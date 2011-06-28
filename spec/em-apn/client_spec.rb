require "spec_helper"

describe EventMachine::APN::Client do
  def new_client(*args)
    client = nil
    EM.run_block {
      client = EM.connect("localhost", 8888, EventMachine::APN::Client, *args)
    }
    client
  end

  describe ".connect" do
    let(:client) { double(EventMachine::APN::Client) }

    it "returns an EM connection" do
      expected_args = ["HOST", 2195, EM::APN::Client, {:key => "KEY", :cert => "CERT"}]
      EM.should_receive(:connect).with(*expected_args).and_return(client)

      EM::APN::Client.connect(
        :gateway => "HOST",
        :key     => "KEY",
        :cert    => "CERT"
      ).should == client
    end

    context "configuring the gateway" do
      let(:options) { {:key => ENV["APN_KEY"], :cert => ENV["APN_CERT"]} }

      it "defaults to Apple's sandbox (gateway.sandbox.push.apple.com)" do
        expected_args = ["gateway.sandbox.push.apple.com", 2195, EM::APN::Client, options]
        EM.should_receive(:connect).with(*expected_args).and_return(client)
        EM::APN::Client.connect.should == client
      end

      it "uses an environment variable for the gateway host (APN_GATEWAY) if specified" do
        original_apn_gateway = ENV["APN_GATEWAY"]
        ENV["APN_GATEWAY"] = "localhost"

        expected_args = ["localhost", 2195, EM::APN::Client, options]
        EM.should_receive(:connect).with(*expected_args).and_return(client)
        EM::APN::Client.connect.should == client

        ENV["APN_GATEWAY"] = original_apn_gateway
      end

      it "switches to the production gateway if APN_ENV is set to 'production'" do
        ENV["APN_ENV"] = "production"

        expected_args = ["gateway.push.apple.com", 2195, EM::APN::Client, options]
        EM.should_receive(:connect).with(*expected_args).and_return(client)
        EM::APN::Client.connect.should == client

        ENV["APN_ENV"] = nil
      end
    end

    context "configuring SSL" do
      it "falls back to environment variables for key and cert (APN_KEY and APN_CERT) if they are unspecified" do
        original_apn_key  = ENV["APN_KEY"]
        original_apn_cert = ENV["APN_CERT"]

        ENV["APN_KEY"]  = "path/to/key.pem"
        ENV["APN_CERT"] = "path/to/cert.pem"

        expected_args = ["gateway.sandbox.push.apple.com", 2195, EM::APN::Client, {
          :key  => "path/to/key.pem",
          :cert => "path/to/cert.pem"
        }]
        EM.should_receive(:connect).with(*expected_args).and_return(client)
        EM::APN::Client.connect.should == client

        ENV["APN_KEY"]  = original_apn_key
        ENV["APN_CERT"] = original_apn_cert
      end

      it "key and cert are used to start SSL" do
        EM::APN::Client.any_instance.should_receive(:start_tls).with(
          :private_key_file => "path/to/key.pem",
          :cert_chain_file  => "path/to/cert.pem",
          :verify_peer      => false
        )
        EM.run_block do
          EM::APN::Client.connect(:key => "path/to/key.pem", :cert => "path/to/cert.pem")
        end
      end
    end
  end

  describe "#deliver" do
    let(:token) { "fe9515ba7556cfdcfca6530235c95dff682fac765838e749a201a7f6cf3792e6" }

    it "sends a Notification object" do
      notification = EM::APN::Notification.new(token, :alert => "Hello world")
      delivered = nil

      EM.run_block do
        client = EM::APN::Client.connect
        client.stub(:send_data).and_return do |data|
          delivered = data.unpack("cNNnH64na*")
          nil
        end
        client.deliver(notification)
      end

      delivered[4].should == token
      delivered[6].should == Yajl::Encoder.encode({:aps => {:alert => "Hello world"}})
    end
  end

  describe "#closed?" do
    it "returns true if the connection has been closed" do
      client = nil

      EM.run_block do
        client = EM::APN::Client.connect
        client.should_not be_closed
        client.close_connection
      end

      client.should be_closed
    end
  end
end
