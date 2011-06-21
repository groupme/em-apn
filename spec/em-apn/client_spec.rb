require "spec_helper"

describe EventMachine::APN::Client do
  def new_client(*args)
    client = nil
    EM.run_block {
      client = EM.connect("localhost", 8888, EventMachine::APN::Client, *args)
    }
    client
  end

  describe ".setup" do
    let(:client) { double(EventMachine::APN::Client) }

    it "takes care of setting up the EM::Connection for you" do
      EM.should_receive(:connect).with("gateway.sandbox.push.apple.com", 2195, EventMachine::APN::Client, {}).and_return(client)
      EM::APN::Client.setup.should == client
    end

    it "sets the gateway explicitly if :gateway is passed" do
      EM.should_receive(:connect).with("some.crazy.gateway", 2195, EventMachine::APN::Client, {}).and_return(client)
      EM::APN::Client.setup(:gateway => "some.crazy.gateway").should == client
    end

    it "sets the gateway to the production gateway if APN_ENV is set to production" do
      ENV["APN_ENV"] = "production"
      EM.should_receive(:connect).with("gateway.push.apple.com", 2195, EventMachine::APN::Client, {}).and_return(client)
      EM::APN::Client.setup.should == client
      ENV["APN_ENV"] = nil
    end

    it "passes key and cert options along as well" do
      certs = {:key => "key", :cert => "cert"}
      EM.should_receive(:connect).with("gateway.sandbox.push.apple.com", 2195, EventMachine::APN::Client, certs).and_return(client)
      EM::APN::Client.setup(certs).should == client
    end
  end

  describe "#initialize" do
    it "accepts the key and cert as arguments" do
      EM::APN::Client.any_instance.should_receive(:start_tls).with(
        :private_key_file => "path/to/key.pem",
        :cert_chain_file  => "path/to/cert.pem",
        :verify_peer      => false
      )
      client = new_client(:key => "path/to/key.pem", :cert => "path/to/cert.pem")
    end

    it "defaults #key and #cert to environment variables if unpassed" do
      original_apn_key  = ENV["APN_KEY"]
      original_apn_cert = ENV["APN_CERT"]

      ENV["APN_KEY"]  = "path/to/key.pem"
      ENV["APN_CERT"] = "path/to/cert.pem"

      EM::APN::Client.any_instance.should_receive(:start_tls).with(
        :private_key_file => "path/to/key.pem",
        :cert_chain_file  => "path/to/cert.pem",
        :verify_peer      => false
      )
      client = new_client

      ENV["APN_KEY"]  = original_apn_key
      ENV["APN_CERT"] = original_apn_cert
    end

    it "raises an exception if neither are set/passed" do
      original_apn_key  = ENV["APN_KEY"]
      original_apn_cert = ENV["APN_CERT"]

      ENV["APN_KEY"]  = nil
      ENV["APN_CERT"] = nil

      expect { client = new_client }.to raise_error

      ENV["APN_KEY"]  = original_apn_key
      ENV["APN_CERT"] = original_apn_cert
    end
  end

  describe "#deliver" do
    let(:token) { "fe9515ba7556cfdcfca6530235c95dff682fac765838e749a201a7f6cf3792e6" }

    it "sends a Notification object" do
      delivered = nil
      client = new_client
      client.stub(:send_data).and_return do |data|
        delivered = data.unpack("cNNnH64na*")
        nil
      end

      notification = EM::APN::Notification.new(token, :alert => "Hello world")
      client.deliver(notification)
      delivered[4].should == token
      delivered[6].should == {:aps => {:alert => "Hello world"}}.to_json
    end
  end
end
