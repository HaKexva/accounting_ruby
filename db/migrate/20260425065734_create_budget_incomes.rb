class CreateBudgetIncomes < ActiveRecord::Migration[8.1]
  def change
    create_table :revenue_budget do |t|
      t.string :item, null: false
      t.decimal :amount, null: false
      t.text :note

      t.timestamps
    end
  end
end
