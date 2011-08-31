require "eventmachine"
require "multi_json"
require "logger"
require "em-apn/client"
require "em-apn/notification"

module EventMachine
  module APN
    def self.push(token, aps = {}, custom = {}, options = {})
      notification = Notification.new(token, aps, custom, options)

      @client = Client.connect if @client.nil? || @client.closed?
      @client.deliver(notification)
    end

    def self.client=(new_client)
      @client = new_client
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.logger=(new_logger)
      @logger = new_logger
    end
  end
end
