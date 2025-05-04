module Marketing
  module Lead
    class Entity < ApplicationRecord
      self.table_name = "marketing_leads"

      enum :status, { interested: 0, customer: 1, canceled: 2 }

      validates :status, presence: true

      def do_something_dangerous
      end
    end
  end
end
