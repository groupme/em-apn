# encoding: UTF-8

module EventMachine
  module APN
    class Notification
      DATA_MAX_BYTES    = 256

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
        MultiJson.encode(@custom.merge(:aps => @aps))
      end

      # Documentation about this format is here:
      # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html
      def data
        identifier = @identifier || 0
        expiry     = @expiry || 0
        size = [payload].pack("a*").size
        data_array = [1, identifier, expiry, 32, token, size, payload]
        data_array.pack("cNNnH*na*")
      end

      def validate!
        if data.size > DATA_MAX_BYTES
          error = "max is #{DATA_MAX_BYTES} bytes, but got #{data.size}: #{payload.inspect}"
          raise PayloadTooLarge.new(error)
        else
          true
        end
      end

      def identifier=(new_identifier)
        @identifier = new_identifier.to_i
      end

      def truncate_alert!
        while data.size > DATA_MAX_BYTES && !@aps["alert"].nil? && @aps["alert"].size > 0
          @aps["alert"] = @aps["alert"][0..-2]
        end
      end

    end
  end
end
