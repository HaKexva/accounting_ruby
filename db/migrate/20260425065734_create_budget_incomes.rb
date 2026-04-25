class CreateBudgetIncomes < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_incomes do |t|
      t.date :time, null: false
      t.string :item, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :note

      t.timestamps
    end

    add_index :budget_incomes, :time
  end
end
