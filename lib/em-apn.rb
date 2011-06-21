require "eventmachine"
require "json"
require "logger"
require "em-apn/client"
require "em-apn/notification"

module EventMachine
  module APN
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.logger=(new_logger)
      @logger = new_logger
    end
  end
end
