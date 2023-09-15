module Finance
  module Card
    class Entity < ApplicationRecord
      self.table_name = "finance_cards"

      belongs_to :client,
                 inverse_of: :cards,
                 class_name: "Finance::Client::Entity"

      validates :number, presence: true
      validates :month_expiration, presence: true
      validates :year_expiration, presence: true
      validates :owner_full_name, presence: true
      validates :security_code, presence: true
    end
  end
end
