require "eventmachine"
require "json"
require "logger"
require "em-apn/notification"

module EventMachine
  module APN
    module Client
      def deliver(notification)
        logger.info("SEND #{notification.token} #{notification.payload}")
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
          :private_key_file => ENV["APN_KEY"],
          :cert_chain_file  => ENV["APN_CERT"],
          :verify_peer      => false
        )
      end

      def receive_data(data)
        data_array = data.unpack("ccN")
        logger.info("RECV #{data_array.inspect}")

        if @on_receipt_callback
          @on_receipt_callback.call(data_array)
        end
      end

      private

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
