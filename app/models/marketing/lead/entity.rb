module Marketing
  module Lead
    class Entity < ApplicationRecord
      self.table_name = "marketing_leads"
    end
  end
end
