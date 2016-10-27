module EventMachine
  module APN
    class ConnectionSplitter

      def initialize (clients)
        add_clients(clients) if !clients.empty?
      end

      def get_client (key)
        @clients[key]
      end

      def deliver (notification)
        client = get_client(notification.transport)
        if client == nil
          EM::APN.logger.error("Missing push connection for transport=#{notification.transport}")
          return
        end
        client.deliver(notification)
      end

      def add_clients (clients)
        @clients = clients
      end

    end
  end
end
