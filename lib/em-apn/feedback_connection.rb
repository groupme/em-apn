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
        @buf = StringIO.new('', 'a+b')
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
        @buf.write data
        return if @buf.size < 38

        @buf.rewind
        while @buf.size - @buf.pos >= 38
          attempt = FailedDeliveryAttempt.new(@buf.read(38))
          EM::APN.logger.warn(attempt.to_s)

          if client.feedback_callback
            client.feedback_callback.call(attempt)
          end
        end
        @buf.reopen(@buf.read, 'a+b')
      end

      def unbind
        @disconnected = true
        EM::APN.logger.info("Feedback connection closed")
      end
    end
  end
end
