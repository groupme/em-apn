module EventMachine
  module APN
    class ErrorResponse
      DESCRIPTION = {
        0   => "No errors encountered",
        1   => "Processing error",
        2   => "Missing device token",
        3   => "Missing topic",
        4   => "Missing payload",
        5   => "Invalid token size",
        6   => "Invalid topic size",
        7   => "Invalid payload size",
        8   => "Invalid token",
        255 => "None (unknown)"
      }

      attr_reader :command, :status_code, :identifier

      def initialize(command, status_code, identifier)
        @command     = command
        @status_code = status_code
        @identifier  = identifier
      end

      def to_s
        "CODE=#{@status_code} ID=#{@identifier} DESC=#{description}"
      end

      def description
        DESCRIPTION[@status_code] || "Missing description"
      end
    end
  end
end
