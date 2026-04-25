class CreateRealExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :real_expenses do |t|
      t.date :transaction_date, null: false
      t.string :transaction_item, null: false
      t.string :category, null: false
      t.string :payment_method, null: false
      t.string :credit_card_payment_method
      t.string :payment_timing
      t.decimal :actual_amount, precision: 12, scale: 2, null: false
      t.string :payment_platform
      t.decimal :posted_amount, precision: 12, scale: 2
      t.text :note

      t.timestamps
    end

    add_index :real_expenses, :transaction_date
    add_index :real_expenses, :category
    add_index :real_expenses, :payment_method
  end
end
