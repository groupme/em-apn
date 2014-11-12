# encoding: UTF-8

require "eventmachine"
require "multi_json"
require "logger"
require "extensions/hash"
require "em-apn/client"
require "em-apn/feedback_connection"
require 'em-apn/failed_delivery_attempt'
require "em-apn/connection"
require "em-apn/notification"
require "em-apn/log_message"
require "em-apn/response"
require "em-apn/error_response"

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
