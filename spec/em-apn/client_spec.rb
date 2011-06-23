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
      client_args = {
        :key  => "KEY",
        :cert => "CERT",
        :host => "HOST",
        :port => "PORT"
      }

      expected_args = ["HOST", "PORT", EventMachine::APN::Client, client_args]
      EM.should_receive(:connect).with(*expected_args).and_return(client)
      EM::APN::Client.connect(client_args).should == client
    end

    it "defaults the gateway to 'gateway.sandbox.push.apple.com' and the port to 2195" do
      expected_args = ["gateway.sandbox.push.apple.com", 2195, EventMachine::APN::Client, {
        :key  => "KEY",
        :cert => "CERT",
        :host => "gateway.sandbox.push.apple.com",
        :port => 2195
      }]

      EM.should_receive(:connect).with(*expected_args).and_return(client)
      EM::APN::Client.connect(:key => "KEY", :cert => "CERT").should == client
    end

    it "falls back to environment variables for key and cert if they are unspecified" do
      original_apn_key  = ENV["APN_KEY"]
      original_apn_cert = ENV["APN_CERT"]

      ENV["APN_KEY"]  = "path/to/key.pem"
      ENV["APN_CERT"] = "path/to/cert.pem"

      expected_args = ["gateway.sandbox.push.apple.com", 2195, EventMachine::APN::Client, {
        :key  => "path/to/key.pem",
        :cert => "path/to/cert.pem",
        :host => "gateway.sandbox.push.apple.com",
        :port => 2195
      }]

      EM.should_receive(:connect).with(*expected_args).and_return(client)
      EM::APN::Client.connect.should == client

      ENV["APN_KEY"]  = original_apn_key
      ENV["APN_CERT"] = original_apn_cert
    end

    it "switches to the production gateway if APN_ENV is set to 'production'" do
      ENV["APN_ENV"] = "production"

      expected_args = ["gateway.push.apple.com", 2195, EventMachine::APN::Client, {
        :key  => ENV["APN_KEY"],
        :cert => ENV["APN_CERT"],
        :host => "gateway.push.apple.com",
        :port => 2195
      }]

      EM.should_receive(:connect).with(*expected_args).and_return(client)
      EM::APN::Client.connect.should == client

      ENV["APN_ENV"] = nil
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
end
