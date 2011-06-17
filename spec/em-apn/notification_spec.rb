require "spec_helper"

describe EventMachine::APN::Notification do
  let(:token) { "fe9515ba7556cfdcfca6530235c95dff682fac765838e749a201a7f6cf3792e6" }

  describe "#initialize" do
    it "raises an exception if the token is blank" do
      expect { EM::APN::Notification.new(nil) }.to raise_error
      expect { EM::APN::Notification.new("") }.to raise_error
    end

    it "raises an exception if the token is less than or greater than 32 bytes" do
      expect { EM::APN::Notification.new("0" * 63) }.to raise_error
      expect { EM::APN::Notification.new("0" * 65) }.to raise_error
    end
  end

  describe "#token" do
    it "returns the token" do
      notification = EM::APN::Notification.new(token)
      notification.token.should == token
    end
  end

  describe "#payload" do
    it "returns aps properties encoded as JSON" do
      notification = EM::APN::Notification.new(token, {
        :alert => "Hello world",
        :badge => 10,
        :sound => "ding.aiff"
      })
      payload = JSON.parse(notification.payload)
      payload["aps"]["alert"].should == "Hello world"
      payload["aps"]["badge"].should == 10
      payload["aps"]["sound"].should == "ding.aiff"
    end

    it "returns custom properties as well" do
      notification = EM::APN::Notification.new(token, {}, {:line => "I'm super bad"})
      payload = JSON.parse(notification.payload)
      payload["line"].should == "I'm super bad"
    end
  end

  describe "#data" do
    it "returns the enhanced notification in the supported binary format" do
      notification = EM::APN::Notification.new(token, {:alert => "Hello world"})
      data = notification.data.unpack("cNNnH64na*")
      data[4].should == token
      data[5].should == notification.payload.length
      data[6].should == notification.payload
    end

    it "defaults the identifier and expiry to 0" do
      notification = EM::APN::Notification.new(token, {:alert => "Hello world"})
      data = notification.data.unpack("cNNnH64na*")
      data[1].should == 0 # Identifier
      data[2].should == 0 # Expiry
    end
  end

  describe "#identifier=" do
    it "sets the identifier, which is returned in the binary data" do
      notification = EM::APN::Notification.new(token)
      notification.identifier = 12345
      notification.identifier.should == 12345

      data = notification.data.unpack("cNNnH64na*")
      data[1].should == notification.identifier
    end

    it "converts everything to an integer" do
      notification = EM::APN::Notification.new(token)
      notification.identifier = "12345"
      notification.identifier.should == 12345
    end

    it "can be set in the initializer" do
      notification = EM::APN::Notification.new(token, {}, {}, {:identifier => 12345})
      notification.identifier.should == 12345
    end
  end

  describe "#expiry=" do
    it "sets the expiry, which is returned in the binary data" do
      epoch = Time.now.to_i
      notification = EM::APN::Notification.new(token)
      notification.expiry = epoch
      notification.expiry.should == epoch

      data = notification.data.unpack("cNNnH64na*")
      data[2].should == epoch
    end

    it "can be set in the initializer" do
      epoch = Time.now.to_i
      notification = EM::APN::Notification.new(token, {}, {}, {:expiry => epoch})
      notification.expiry.should == epoch
    end
  end
end
