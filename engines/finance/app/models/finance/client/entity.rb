module Finance
  module Client
    class Entity < ApplicationRecord
      self.table_name = "finance_clients"

      has_many :cards,
               foreign_key: :finance_client_id,
               inverse_of: :client,
               dependent: :destroy,
               class_name: "::Finance::Card::Entity"

      validates :full_name, presence: true
      validates :email, presence: true
      validates :document, presence: true
    end
  end
end
