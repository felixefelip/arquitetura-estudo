# rbs_inline: enabled

module Marketing
  module Lead
    class Generate
      #: (full_name: String, email: String) -> void
      def initialize(full_name:, email:)
        self.full_name = full_name
        self.email = email
      end

      #: -> Marketing::Lead::Entity
      def call
        Entity.create!(full_name:, email:, status: :interested)
      end

      private

      attr_accessor :full_name #: String
      attr_accessor :email #: String
    end
  end
end
