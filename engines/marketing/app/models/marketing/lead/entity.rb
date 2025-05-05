# rbs_inline: enabled

module Marketing::Lead
  class Entity < ApplicationRecord
    self.table_name = "marketing_leads"

    enum :status, { interested: 0, customer: 1, canceled: 2 }

    validates :status, presence: true

    class << self
      # @rbs (email: String) -> void
      def convert(email:)
        lead = find_by!(email:)

        lead.update!(status: :customer)
      end
    end
  end
end
