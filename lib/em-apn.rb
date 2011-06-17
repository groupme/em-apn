require "eventmachine"
require "json"
require "logger"

module EventMachine
  module APN
    module Client
      def deliver(token, payload_params = {}, options = {})
        raise "Bad push token: #{token}" if token.nil? || (token.length != 64)

        payload = extract_payload(payload_params)
        data    = enhanced_packet(token, payload, options)

        logger.info("SEND #{token} #{payload}")
        send_data(data)
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

      def extract_payload(options)
        aps = {}
        aps[:alert] = options.delete(:alert) || options.delete("alert")
        aps[:badge] = options.delete(:badge) || options.delete("badge")
        aps[:sound] = options.delete(:sound) || options.delete("sound")

        payload = options.merge(:aps => aps)
        payload.to_json
      end

      # Documentation about this format is here:
      # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html
      def enhanced_packet(token, payload, options)
        expiry     = options[:expiry] || options["expiry"] || 0
        identifier = options[:identifier] || options["identifier"] || 0

        data_array = [1, identifier, expiry, 32, token, payload.length, payload]
        data_array.pack("cNNnH*na*")
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
