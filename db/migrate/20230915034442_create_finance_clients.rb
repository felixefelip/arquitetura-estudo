class CreateFinanceClients < ActiveRecord::Migration[7.0]
  def change
    create_table :finance_clients do |t|
      t.string :full_name
      t.string :email
      t.string :document

      t.timestamps
    end
  end
end
