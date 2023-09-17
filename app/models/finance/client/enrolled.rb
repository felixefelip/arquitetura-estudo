module Finance
  module Client
    class Enrolled
      attr_reader :momento, :client_payload

      def initialize(client_payload:)
        @momento = DateTime.current
        @client_payload = client_payload
      end
    end
  end
end
