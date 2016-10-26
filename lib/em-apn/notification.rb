# encoding: UTF-8

module EventMachine
  module APN
    class Notification
      DATA_MAX_BYTES = 2048
      ALERT_KEY = "alert"

      class PayloadTooLarge < StandardError; end
      class InvalidPushToken < StandardError; end

      attr_reader :token, :identifier, :transport
      attr_accessor :expiry

      def initialize(token, aps = {}, custom = {}, options = {})
        parse_token(token)

        @aps    = aps.stringify_keys!
        @custom = custom
        @expiry = options[:expiry]

        self.identifier = options[:identifier] if options[:identifier]
      end

      def payload
        MultiJson.encode(@custom.merge(:aps => @aps))
      end

      def parse_token (token)
        @transport = nil
        # token can be either plain 64 char long apple push token or one prefixed by custom transport as "com.groupme.beta.staging/{original_apple_push_token}"
        token.scan(/^([^\/]+)\/(.*)$/) { |trn, tok|
          @transport = trn.strip
          @token     = tok.strip
        }
        # no prefix detected, use original plain token
        @token ||= token
        raise InvalidPushToken.new("Invalid push token: #{@token}") if @token.nil? || (@token.length != 64)
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
        return unless @aps.has_key?(ALERT_KEY)

        while data.size > DATA_MAX_BYTES && @aps[ALERT_KEY].size > 0
          @aps[ALERT_KEY].chop!
        end
      end

    end
  end
end
