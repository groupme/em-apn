module EventMachine
  module APN
    class FeedbackConnection < EM::Connection
      attr_reader :client

      def initialize(*args)
        super
        @client = args.last
        @disconnected = false
      end

      def disconnected?
        @disconnected
      end

      def post_init
        start_tls(
          :private_key_file => client.key,
          :cert_chain_file  => client.cert,
          :verify_peer      => false
        )
      end

      def connection_completed
        EM::APN.logger.info("Feedback connection completed")
      end

      def receive_data(data)
        attempt = FailedDeliveryAttempt.new(data)
        EM::APN.logger.warn(attempt.to_s)

        if client.feedback_callback
          client.feedback_callback.call(attempt)
        end
      end

      def unbind
        @disconnected = true
        EM::APN.logger.info("Feedback connection closed")
      end
    end
  end
end
