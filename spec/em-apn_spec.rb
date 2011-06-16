require "spec_helper"

describe EventMachine::APN::Client do
  describe "#deliver" do
    before do
      klass = Class.new
      klass.send(:include, EventMachine::APN::Client)
      @client = klass.new

      @delivered = nil
      @client.stub(:send_data).and_return do |data|
        @delivered = data.unpack("cNNnH64na*")
        nil
      end
    end

    context "push token" do
      it "sends the notification to the given token" do
        token = "fe9515ba7556cfdcfca6530235c95dff682fac765838e749a201a7f6cf3792e6"
        @client.deliver(token)
        @delivered[4].should == token
      end

      it "raises an exception if the token is blank" do
        expect { @client.deliver(nil) }.to raise_error
        expect { @client.deliver("") }.to raise_error
      end

      it "raises an exception if the token is less than or greater than 32 bytes" do
        expect { @client.deliver("0" * 63) }.to raise_error
        expect { @client.deliver("0" * 65) }.to raise_error
      end
    end

    context "aps payload" do
    end

    context "custom payload" do
    end

    context "other options" do
    end
  end
end
