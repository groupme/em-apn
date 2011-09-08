# encoding: UTF-8

module EventMachine
  module APN
    class Notification
      PAYLOAD_MAX_BYTES = 256
      class PayloadTooLarge < StandardError;end

      attr_reader :token
      attr_accessor :identifier, :expiry

      def initialize(token, aps = {}, custom = {}, options = {})
        raise "Bad push token: #{token}" if token.nil? || (token.length != 64)

        @token  = token
        @aps    = aps
        @custom = custom

        self.identifier = options[:identifier] if options[:identifier]
        self.expiry = options[:expiry] if options[:expiry]
      end

      def payload
        @payload ||= build_payload
      end

      def data
        @data ||= build_data
      end

      def identifier=(new_identifier)
        @identifier = new_identifier.to_i
      end

      private

      def build_payload
        payload = @custom.merge(:aps => @aps)
        Yajl::Encoder.encode(payload)
      end

      # Documentation about this format is here:
      # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html
      def build_data
        identifier = @identifier || 0
        expiry     = @expiry || 0

        data_array = [1, identifier, expiry, 32, token, payload.length, payload]
        data = data_array.pack("cNNnH*na*")
        if data.size > PAYLOAD_MAX_BYTES
          error = "max is #{PAYLOAD_MAX_BYTES} bytes (got #{data.size})"
          raise PayloadTooLarge.new(error)
        end
        data
      end
    end
  end
end
