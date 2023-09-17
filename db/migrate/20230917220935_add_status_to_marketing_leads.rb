class AddStatusToMarketingLeads < ActiveRecord::Migration[7.0]
  def change
    add_column :marketing_leads, :status, :integer
  end
end
