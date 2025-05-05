# rbs_inline: enabled

module Marketing
  module Lead
    class Entity < ApplicationRecord
      self.table_name = "marketing_leads"

      enum :status, { interested: 0, customer: 1, canceled: 2 }

      validates :status, presence: true

      # @rbs () -> ::Marketing::Lead::Entity::ActiveRecord_Relation
      def do_something_dangerous
        ::Marketing::Lead::Entity.all
      end

      # @rbs () -> Integer
      def teste
        do_something_dangerous.where(status: 0).order(:id).count
      end
    end
  end
end
