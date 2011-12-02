# encoding: UTF-8

require "eventmachine"
require "yajl"
require "logger"
require "em-apn/client"
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
