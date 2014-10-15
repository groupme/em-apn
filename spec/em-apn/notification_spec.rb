# encoding: UTF-8
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
      payload = MultiJson.decode(notification.payload)
      payload["aps"]["alert"].should == "Hello world"
      payload["aps"]["badge"].should == 10
      payload["aps"]["sound"].should == "ding.aiff"
    end

    it "returns custom properties as well" do
      notification = EM::APN::Notification.new(token, {}, {:line => "I'm super bad"})
      payload = MultiJson.decode(notification.payload)
      payload["line"].should == "I'm super bad"
    end

    it "handles string keys" do
      notification = EM::APN::Notification.new(token,
        {
          "alert" => "Hello world",
          "badge" => 10,
          "sound" => "ding.aiff"
        },
        {
          "custom" => "param"
        }
      )
      payload = MultiJson.decode(notification.payload)
      payload["aps"]["alert"].should == "Hello world"
      payload["aps"]["badge"].should == 10
      payload["aps"]["sound"].should == "ding.aiff"
      payload["custom"].should == "param"
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

    it "handles UTF-8 payloads" do
      string = "✓ Please"
      notification = EM::APN::Notification.new(token, {:alert => string})
      data = notification.data.unpack("cNNnH64na*")
      data[4].should == token
      data[5].should == [notification.payload].pack("a*").size
      data[6].force_encoding("UTF-8").should == notification.payload
    end

    it "defaults the identifier and expiry to 0" do
      notification = EM::APN::Notification.new(token, {:alert => "Hello world"})
      data = notification.data.unpack("cNNnH64na*")
      data[1].should == 0 # Identifier
      data[2].should == 0 # Expiry
    end
  end

  describe "#validate!" do
    it "raises PayloadTooLarge error if PAYLOAD_MAX_BYTES exceeded" do
      notification = EM::APN::Notification.new(token, {:alert => "X" * 2050})

      lambda {
        notification.validate!
      }.should raise_error(EM::APN::Notification::PayloadTooLarge)
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

  describe "#truncate_alert!" do
    context "when the data size would exceed the APN limit" do
      it "truncates the alert" do
        notification = EM::APN::Notification.new(token, { "alert" => "X" * 2050 })
        notification.data.size.should be > EM::APN::Notification::DATA_MAX_BYTES

        notification.truncate_alert!
        notification.data.size.should be <= EM::APN::Notification::DATA_MAX_BYTES
        parsed_payload = MultiJson.decode(notification.payload)
        parsed_payload["aps"]["alert"].size.should == 1983
      end

      it "truncates the alert properly when symbol payload keys are used" do
        notification = EM::APN::Notification.new(token, { "alert" => "X" * 300 })
        notification.truncate_alert!
        notification.data.size.should be <= EM::APN::Notification::DATA_MAX_BYTES
      end

      it "truncates the alert properly when it is JSON serialized into a different size" do
        notification = EM::APN::Notification.new(token, { "alert" => '"' * 2050 })
        notification.truncate_alert!
        parsed_payload = MultiJson.decode(notification.payload)
        parsed_payload["aps"]["alert"].size.should == 991
      end

      it "truncates the alert properly for multi-byte Unicode characters" do
        notification = EM::APN::Notification.new(token, { "alert" => [57352].pack('U') * 2050 })
        notification.truncate_alert!
        parsed_payload = MultiJson.decode(notification.payload)
        parsed_payload["aps"]["alert"].size.should == 661
      end
    end

    context "when the data size would not exceed the APN limit" do
      it "does not change the alert" do
        notification = EM::APN::Notification.new(token, { "alert" => "Hello world" })
        notification.truncate_alert!
        parsed_payload = MultiJson.decode(notification.payload)
        parsed_payload["aps"]["alert"].should == "Hello world"
      end
    end
  end
end
