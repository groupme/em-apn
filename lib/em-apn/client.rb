module EventMachine
  module APN
    class Client < EventMachine::Connection
      SANDBOX_GATEWAY    = "gateway.sandbox.push.apple.com"
      PRODUCTION_GATEWAY = "gateway.push.apple.com"
      PORT = 2195

      # Create a connection to Apple's push notification gateway
      #
      # This convenience method will adopt environment variables and defaults
      # for the necessary parameters -- gateway host, port, key, and cert.
      #
      # You can use EM.connect yourself, but in that case, be sure to pass along
      # the key and cert for the SSL connection.
      def self.connect(options = {})
        options = options.dup
        options[:key]  ||= ENV["APN_KEY"]
        options[:cert] ||= ENV["APN_CERT"]

        gateway = options.delete(:gateway)
        gateway ||= ENV["APN_GATEWAY"]
        gateway ||= (ENV["APN_ENV"] == "production") ? PRODUCTION_GATEWAY : SANDBOX_GATEWAY

        EM.connect(gateway, PORT, self, options)
      end

      def self.gateway
        (ENV["APN_ENV"] == "production") ? "gateway.push.apple.com" : "gateway.sandbox.push.apple.com"
      end

      def initialize(options = {})
        @key    = options[:key]
        @cert   = options[:cert]
        @closed = false
      end

      def deliver(notification)
        EM::APN.logger.info("APN SEND #{notification.token} #{notification.payload}")
        send_data(notification.data)
      end

      def on_receipt(&block)
        @on_receipt_callback = block
      end

      def closed?
        @closed
      end

      #
      # EM callbacks
      #

      def post_init
        start_tls(
          :private_key_file => @key,
          :cert_chain_file  => @cert,
          :verify_peer      => false
        )
      end

      def receive_data(data)
        data_array = data.unpack("ccN")
        EM::APN.logger.info("APN RECV #{data_array.inspect}")

        if @on_receipt_callback
          @on_receipt_callback.call(data_array)
        end
      end

      # The caller should attempt to detect closed connections by calling
      # Client#closed? and re-connecting.
      def unbind
        @closed = true
        EM::APN.logger.info("Connection closed")
      end
    end
  end
end
