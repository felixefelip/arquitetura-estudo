module Marketing
  module Lead
    class Convert
      def initialize(email:)
        self.email = email
      end

      def self.call(email:)
        new(email:).call
      end

      def call
        lead = Entity.find_by!(email:)
        lead.update!(status: :customer)
      end

      private

      attr_accessor :email
    end
  end
end
