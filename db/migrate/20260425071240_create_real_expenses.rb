class CreateRealExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :actual_expenditure do |t|
      t.date :transaction_date, null: false
      t.string :transaction_item, null: false
      t.string :category, null: false
      t.string :payment_method, null: false
      t.string :credit_card_payment_method
      t.string :payment_timing
      t.decimal :actual_amount, null: false
      t.string :payment_platform
      t.decimal :posted_amount, null: false
      t.text :note

      t.timestamps
    end

    add_index :actual_expenditure, [:transaction_date, :transaction_item]
  end
end
