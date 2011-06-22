module EventMachine
  module APN
    class Client < EventMachine::Connection
      SANDBOX_GATEWAY    = "gateway.sandbox.push.apple.com"
      PRODUCTION_GATEWAY = "gateway.push.apple.com"
      PORT = 2195
      MAX_RETRIES = 10

      # Create a connection to Apple's push notification gateway
      #
      # This is the preferred public interface. Using EM.connect yourself is fraught with danger
      # given that we rely upon some options to set the host and port (see #unbind).
      #
      # So don't do it.
      def self.connect(options = {})
        options = options.dup
        options[:port] ||= PORT
        options[:host] ||= (ENV["APN_ENV"] == "production") ? PRODUCTION_GATEWAY : SANDBOX_GATEWAY
        options[:key]  ||= ENV["APN_KEY"]
        options[:cert] ||= ENV["APN_CERT"]

        # Passing the host and port along for EM#reconnect in #unbind
        EM.connect(options[:host], options[:port], self, options)
      end

      def self.gateway
        (ENV["APN_ENV"] == "production") ? "gateway.push.apple.com" : "gateway.sandbox.push.apple.com"
      end

      def initialize(options = {})
        @host = options[:host]
        @port = options[:port]
        @key  = options[:key]  || ENV["APN_KEY"]
        @cert = options[:cert] || ENV["APN_CERT"]
      end

      def deliver(notification)
        EM::APN.logger.info("APN SEND #{notification.token} #{notification.payload}")
        send_data(notification.data)
      end

      def on_receipt(&block)
        @on_receipt_callback = block
      end

      #
      # EM callbacks
      #

      def connection_completed
        EM::APN.logger.info("Connection established")
      end

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

      # If the connection drops, attempt to reconnect with exponential decay
      def unbind
        EM::APN.logger.info("Connection closed")

        # Wrap up retry logic in next_tick so that this doesn't fire if the event loop
        # itself is being closed (normal exit).
        EM.next_tick do
          @reconnect_retries ||= 0

          if @reconnect_retries >= MAX_RETRIES
            EM::APN.logger.error("Max retries exceeded (#{MAX_RETRIES})... giving up!")
          else
            retry_interval = 2 ** @reconnect_retries
            @reconnect_retries += 1
            EM::APN.logger.warn("Reconnecting in #{retry_interval} seconds...")

            EM.add_timer(retry_interval) do
              EM::APN.logger.warn("Reconnecting to #{@host}")
              reconnect(@host, @port)
            end
          end
        end
      end

    end
  end
end
