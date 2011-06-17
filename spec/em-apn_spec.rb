require "spec_helper"

describe EventMachine::APN::Client do
  describe "#deliver" do
    let(:token) { "fe9515ba7556cfdcfca6530235c95dff682fac765838e749a201a7f6cf3792e6" }

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

    it "sends a Notification object" do
      notification = EM::APN::Notification.new(token, :alert => "Hello world")
      @client.deliver(notification)
      @delivered[4].should == token
      @delivered[6].should == {:aps => {:alert => "Hello world"}}.to_json
    end
  end
end
