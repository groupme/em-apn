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
#       EM::APN.push(token, aps, custom)
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
      unless instance_methods.include?(:deliver_with_testing)
        def deliver_with_testing(notification)
          EM::APN.deliveries << notification
          deliver_without_testing(notification)
        end
        alias :deliver_without_testing :deliver
        alias :deliver :deliver_with_testing

        def connect
          # Nope
        end

        def send_data(data)
          # Nope
        end
      end
    end
  end
end
