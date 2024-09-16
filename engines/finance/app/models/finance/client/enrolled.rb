module Finance
  module Client
    class Enrolled
      attr_reader :client_payload

      def initialize(client_payload:)
        @momento = DateTime.current
        @client_payload = client_payload
        @name = "finance_client_enrolled"
      end

      def momento
        @momento
      end

      def name
        @name
      end
    end
  end
end
