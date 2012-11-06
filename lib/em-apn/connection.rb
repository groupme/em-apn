module EventMachine
  module APN
    class Connection < EM::Connection
      attr_reader :client

      def initialize(*args)
        super
        @client = args.last
        @disconnected = false
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
        client.close_callback.call if client.close_callback
      end
    end
  end
end
