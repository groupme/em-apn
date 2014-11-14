# encoding: UTF-8

module EventMachine
  module APN
    class Client
      SANDBOX_GATEWAY    = "gateway.sandbox.push.apple.com"
      PRODUCTION_GATEWAY = "gateway.push.apple.com"
      PORT               = 2195
      SANDBOX_FEEDBACK_GATEWAY    = "feedback.sandbox.push.apple.com"
      PRODUCTION_FEEDBACK_GATEWAY = "feedback.push.apple.com"
      FEEDBACK_PORT      = 2196


      attr_reader :gateway, :port, :key, :cert, :connection, :error_callback, :close_callback, :open_callback
      attr_reader :feedback_connection, :feedback_gateway, :feedback_port, :feedback_callback

      # A convenience method for creating and connecting.
      def self.connect(options = {})
        new(options).tap do |client|
          client.connect
          client.connect_feedback
        end
      end

      def initialize(options = {})
        @key  = options[:key]  || ENV["APN_KEY"]
        @cert = options[:cert] || ENV["APN_CERT"]
        @port = options[:port] || PORT

        @gateway = options[:gateway] || ENV["APN_GATEWAY"]
        @gateway ||= (ENV["APN_ENV"] == "production") ? PRODUCTION_GATEWAY : SANDBOX_GATEWAY


        @feedback_gateway = options[:feedback_gateway] || ENV["APN_FEEDBACK_GATEWAY"]
        @feedback_gateway ||= (ENV["APN_ENV"] == "production") ? PRODUCTION_FEEDBACK_GATEWAY : SANDBOX_FEEDBACK_GATEWAY
        @feedback_port = options[:feedback_port] || FEEDBACK_PORT

        @connection = nil
        @feedback_connection = nil
      end

      def connect
        @connection = EM.connect(gateway, port, Connection, self)
      end

      def connect_feedback
        @feedback_connection = EM.connect(feedback_gateway, feedback_port, FeedbackConnection, self)
      end

      def deliver(notification)
        notification.validate!
        connect if connection.nil? || connection.disconnected?
        log(notification)
        connection.send_data(notification.data)
      end

      def on_error(&block)
        @error_callback = block
      end

      def on_close(&block)
        @close_callback = block
      end

      def on_open(&block)
        @open_callback = block
      end

      def on_feedback(&block)
        @feedback_callback = block
      end

      def log(notification)
        EM::APN.logger.info("TOKEN=#{notification.token} PAYLOAD=#{notification.payload.inspect}")
      end
    end
  end
end
