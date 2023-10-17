module Finance
  module Client
    class Enrolled
      attr_reader :momento, :client_payload, :name

      def initialize(client_payload:)
        @momento = DateTime.current
        @client_payload = client_payload
        @name = "finance_client_enrolled"
      end
    end
  end
end
