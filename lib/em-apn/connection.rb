module EventMachine
  module APN
    class Connection < EM::Connection
      attr_reader :client, :ssl_negotiated_callback


      def initialize(*args)
        super
        @client = args.last
        @disconnected = false
        @ssl_negotiated = false
      end

      def disconnected?
        @disconnected
      end

      def post_init
        start_tls(
          :private_key_file => client.key,
          :cert_chain_file  => client.cert,
          :verify_peer      => false
        )
      end

      def connection_completed
        EM::APN.logger.info("Connection completed")
        client.open_callback.call if client.open_callback
      end

      def ssl_handshake_completed
        EM::APN.logger.info("SSL negotiated using #{@client.key}")
        ssl_negotiated!
      end

      def receive_data(data)
        data_array = data.unpack("ccN")
        error_response = ErrorResponse.new(*data_array)
        EM::APN.logger.warn(error_response.to_s)

        if client.error_callback
          client.error_callback.call(error_response)
        end
      end

      def unbind
        @disconnected = true
        EM::APN.logger.info("Connection closed")
        EM::APN.logger.info("Connection was not possible to establish using #{@client.key}") if !ssl_negotiated?
        client.close!
      end

      def ssl_negotiated!
        @ssl_negotiated = true
        @ssl_negotiated_callback.call if @ssl_negotiated_callback
      end

      def on_ssl_negotiated (&block)
        @ssl_negotiated_callback = block
      end

      def ssl_negotiated?
        @ssl_negotiated
      end

    end
  end
end
