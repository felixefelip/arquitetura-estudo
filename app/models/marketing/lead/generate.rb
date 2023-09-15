module Marketing
  module Lead
    class Generate
      def initialize(full_name:, email:)
        self.full_name = full_name
        self.email = email
      end

      def self.call(full_name:, email:)
        new(full_name:, email:).call
      end

      def call
        Entity.create!(full_name:, email:)
      end

      private

      attr_accessor :full_name, :email
    end
  end
end
