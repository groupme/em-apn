module EventMachine
  module APN
    class Response
      def initialize(notification)
        @notification = notification
      end

      def to_s
        "TOKEN=#{@notification.token}"
      end
    end
  end
end
