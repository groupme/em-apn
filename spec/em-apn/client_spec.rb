require "spec_helper"

describe EventMachine::APN::Client do
  def new_client(*args)
    client = nil
    EM.run_block {
      client = EM.connect("localhost", 8888, EventMachine::APN::Client, *args)
    }
    client
  end

  describe ".new" do
    it "creates a new client without a connection" do
      client = EM::APN::Client.new
      client.connection.should be_nil
    end

    context "configuring the gateway" do
      before do
        ENV["APN_GATEWAY"] = nil
      end

      let(:options) { {:key => ENV["APN_KEY"], :cert => ENV["APN_CERT"]} }

      it "defaults to Apple's sandbox (gateway.sandbox.push.apple.com)" do
        client = EM::APN::Client.new
        client.gateway.should == "gateway.sandbox.push.apple.com"
        client.port.should == 2195
      end

      it "uses an environment variable for the gateway host (APN_GATEWAY) if specified" do
        ENV["APN_GATEWAY"] = "localhost"

        client = EM::APN::Client.new
        client.gateway.should == "localhost"
        client.port.should == 2195
      end

      it "switches to the production gateway if APN_ENV is set to 'production'" do
        ENV["APN_ENV"] = "production"

        client = EM::APN::Client.new
        client.gateway.should == "gateway.push.apple.com"
        client.port.should == 2195

        ENV["APN_ENV"] = nil
      end

      it "takes arguments for the gateway and port" do
        client = EM::APN::Client.new(:gateway => "localhost", :port => 3333)
        client.gateway.should == "localhost"
        client.port.should == 3333
      end
    end

    context "configuring SSL" do
      it "falls back to environment variables for key and cert (APN_KEY and APN_CERT) if they are unspecified" do
        ENV["APN_KEY"]  = "path/to/key.pem"
        ENV["APN_CERT"] = "path/to/cert.pem"

        client = EM::APN::Client.new
        client.key.should == "path/to/key.pem"
        client.cert.should == "path/to/cert.pem"
      end

      it "takes arguments for the key and cert" do
        client = EM::APN::Client.new(:key => "key.pem", :cert => "cert.pem")
        client.key.should == "key.pem"
        client.cert.should == "cert.pem"
      end
    end
  end

  describe "#connect" do
    it "creates a connection to the gateway" do
      client = EM::APN::Client.new
      client.connection.should be_nil

      EM.run_block { client.connect }
      client.connection.should be_an_instance_of(EM::APN::Connection)
    end

    it "passes the client to the new connection" do
      client = EM::APN::Client.new
      connection = double(EM::APN::Connection).as_null_object

      EM::APN::Connection.should_receive(:new).with(instance_of(Fixnum), client).and_return(connection)
      EM.run_block { client.connect }
    end
  end

  describe "#deliver" do
    let(:token) { "fe9515ba7556cfdcfca6530235c95dff682fac765838e749a201a7f6cf3792e6" }

    it "sends a Notification object" do
      notification = EM::APN::Notification.new(token, :alert => "Hello world")
      delivered = nil

      EM.run_block do
        client = EM::APN::Client.new
        client.connect
        client.connection.stub(:send_data).and_return do |data|
          delivered = data.unpack("cNNnH64na*")
          nil
        end
        client.deliver(notification)
      end

      delivered[4].should == token
      delivered[6].should == Yajl::Encoder.encode({:aps => {:alert => "Hello world"}})
    end

    it "logs a message" do
      alert = "Hello world this is a long push notification to you"

      test_log = StringIO.new
      EM::APN.logger = Logger.new(test_log)

      notification = EM::APN::Notification.new(token, "alert" => alert)

      EM.run_block do
        client = EM::APN::Client.new
        client.deliver(notification)
      end

      test_log.rewind
      test_log.read.should include("TOKEN=#{token} ALERT=#{alert[0..49]}")
    end
  end

  describe "#on_error" do
    it "sets a callback that is invoked when we receive data from Apple" do
      error = nil

      EM.run_block do
        client = EM::APN::Client.new
        client.connect
        client.on_error { |e| error = e }
        client.connection.receive_data([8, 8, 0].pack("ccN"))
      end

      error.should be

      error.command.should == 8
      error.status_code.should == 8
      error.identifier.should == 0

      error.description.should == "Invalid token"
      error.to_s.should == "CODE=8 ID=0 DESC=Invalid token"
    end
  end

  describe "#on_close" do
    it "sets a callback that is invoked when the connection closes" do
      called = false

      EM.run_block do
        client = EM::APN::Client.new
        client.on_close { called = true }
        client.connect # This should unbind immediately.
      end

      called.should be_true
    end
  end
end
