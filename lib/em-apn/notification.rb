module EventMachine
  module APN
    class Notification
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
        payload.to_json
      end

      # Documentation about this format is here:
      # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html
      def build_data
        identifier = @identifier || 0
        expiry     = @expiry || 0

        data_array = [1, identifier, expiry, 32, token, payload.length, payload]
        data_array.pack("cNNnH*na*")
      end
    end
  end
end
