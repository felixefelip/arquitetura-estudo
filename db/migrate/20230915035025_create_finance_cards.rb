class CreateFinanceCards < ActiveRecord::Migration[7.0]
  def change
    create_table :finance_cards do |t|
      t.string :owner_full_name
      t.string :number
      t.integer :month_expiration
      t.integer :year_expiration
      t.integer :security_code
      t.references :finance_client, null: false, foreign_key: true

      t.timestamps
    end
  end
end
