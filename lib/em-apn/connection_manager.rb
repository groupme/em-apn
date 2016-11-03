module EventMachine
  module APN
    class ConnectionManager

      attr_reader :failed_delivery_callback

      def initialize (*clients)
        add_clients(*clients) if !clients.empty?
      end

      def active_client
        @clients.first
      end

      def cycle_clients
        return unless @clients.length > 1
        client = @clients.shift
        client.handover_to(active_client)
        @clients << client
      end

      def deliver (notification)
        active_client.deliver(notification)
      end

      def add_clients (*clients)
        clients.each do |client|
          client.on_close do
            if !client.connection.ssl_negotiated?
              cycle_clients
            end
          end
        end
        @clients = clients
      end

    end
  end
end
