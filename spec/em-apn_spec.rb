require "spec_helper"

describe EventMachine::APN do
  describe ".push" do
    let(:token) { "fe9515ba7556cfdcfca6530235c95dff682fac765838e749a201a7f6cf3792e6" }

    before do
      EM::APN.deliveries.clear
    end

    it "delivers push notification through a simple interface" do
      expect {
        EM.run_block do
          EM::APN.push(token, :alert => "Hello world")
        end
      }.to change { EM::APN.deliveries.size }.by(1)

      notification = EM::APN.deliveries.first
      notification.token.should == token
      notification.payload.should == Yajl::Encoder.encode({:aps => {:alert => "Hello world"}})
    end

    it "instantiates a single, persistent APN connection" do
      EM::APN.client = nil

      expect {
        EM.run_block do
          client = EM::APN::Client.connect
          EM.should_receive(:connect).once.and_return(client)

          EM::APN.push(token, :alert => "Hello world")
          EM::APN.push(token, :alert => "Hello world")
          EM::APN.push(token, :alert => "Hello world")
        end
      }.to change { EM::APN.deliveries.size }.by(3)
    end

    it "re-connects if a connection closes" do
      EM::APN.client = nil

      expect {
        EM.run_block do
          client_1 = EM::APN::Client.connect
          client_1.should_receive(:closed?).and_return(true)
          client_2 = EM::APN::Client.connect

          EM.should_receive(:connect).ordered.and_return(client_1)
          EM.should_receive(:connect).ordered.and_return(client_2)

          EM::APN.push(token, :alert => "Hello world")
          EM::APN.push(token, :alert => "Hello world")
          EM::APN.push(token, :alert => "Hello world")
        end
      }.to change { EM::APN.deliveries.size }.by(3)
    end
  end
end
