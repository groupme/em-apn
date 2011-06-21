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
      notification.payload.should == {:aps => {:alert => "Hello world"}}.to_json
    end

    it "only ever instantiates a single, persistent APN connection" do
      EM::APN.client = nil

      expect {
        EM.run_block do
          client = EM::APN::Client.setup
          EM.should_receive(:connect).once.and_return(client)

          EM::APN.push(token, :alert => "Hello world")
          EM::APN.push(token, :alert => "Hello world")
          EM::APN.push(token, :alert => "Hello world")
        end
      }.to change { EM::APN.deliveries.size }.by(3)
    end
  end
end
