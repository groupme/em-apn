module EventMachine
  module APN
    class Client < EventMachine::Connection
      def initialize(options = {})
        @key  = options[:key]  || ENV["APN_KEY"]
        @cert = options[:cert] || ENV["APN_CERT"]

        raise "SSL key is missing" if @key.nil? || @key.empty?
        raise "SSL certificate is missing" if @cert.nil? || @cert.empty?
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
    end
  end
end
