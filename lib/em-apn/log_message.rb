module EventMachine
  module APN
    class LogMessage
      def initialize(response)
        @response = response
      end

      def log
        EM::APN.logger.debug(@response.to_s)
      end
    end
  end
end
