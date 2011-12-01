# Test helper for EM::APN
#
# To use this, start by simply requiring this file after EM::APN has already
# been loaded
#
#     require "em-apn"
#     require "em-apn/test_helper"
#
# This will nullify actual deliveries and instead, push them onto an accessible
# list:
#
#     expect {
#       client.deliver('notification)
#     }.to change { EM::APN.deliveries.size }.by(1)
#
#     notification = EM::APN.deliveries.first
#     notification.should be_an_instance_of(EM::APN::Notification)
#     notification.payload.should == ...
#
module EventMachine
  module APN
    def self.deliveries
      @deliveries ||= []
    end

    Client.class_eval do
      def connect
        # No-op
      end

      def deliver(notification)
        log(notification)
        EM::APN.deliveries << notification
      end
    end
  end
end
