module EventMachine
  module APN
    class Client < EventMachine::Connection
      SANDBOX_GATEWAY    = "gateway.sandbox.push.apple.com"
      PRODUCTION_GATEWAY = "gateway.push.apple.com"
      PORT = 2195

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

        @reconnect_retries = 0
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

        if @reconnect_retries > 0
          EM::APN.logger.info("Reconnect detected... re-starting TLS")
          start_tls(
            :private_key_file => @key,
            :cert_chain_file  => @cert,
            :verify_peer      => false
          )
          @reconnect_retries = 0
        end
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

      # Crazy crazy crazy
      #
      # Apple severs the connection if there are any errors (bad token and the like).
      # This will immediately attempt to reconnect, and if that fails, it will start
      # to back off exponentially with an upper limit of sixty seconds between attempts.
      #
      # And it will keep trying forever and ever.
      #
      # Note also that #post_init isn't called as a result of #reconnect, so the TLS
      # setup occurs inside of #connection_completed for these retries. Ugh.
      #
      # Future work may try to disentangle all this by simply letting the connection
      # die and re-connecting with a brand new client inside of EM::APN.push.
      # Queuing up behind a reconnect at that level is probably preferable since any
      # data that is sent out while this thing is reconnecting is simply dropped.
      def unbind
        EM::APN.logger.info("Connection closed")

        # Wrap up retry logic in next_tick so that this doesn't fire if the event loop
        # itself is being closed (normal exit).
        EM.next_tick do
          @reconnect_retries += 1

          # If this is the first retry, attempt to reconnect immediately.
          # Otherwise, keep retrying on an exponential decay
          if @reconnect_retries == 1
            EM::APN.logger.warn("Reconnecting to #{@host} (attempt #{@reconnect_retries})")
            reconnect(@host, @port)
          else
            retry_interval = 2 ** (@reconnect_retries - 2)
            retry_interval = 60 if retry_interval > 60

            EM::APN.logger.warn("Reconnecting in #{retry_interval} seconds...")

            EM.add_timer(retry_interval) do
              EM::APN.logger.warn("Reconnecting to #{@host} (attempt #{@reconnect_retries})")
              reconnect(@host, @port)
            end
          end
        end
      end

    end
  end
end
