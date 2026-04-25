class CreateBudgetExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_expenses do |t|
      t.date :time, null: false
      t.string :category, null: false
      t.string :item, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :note

      t.timestamps
    end

    add_index :budget_expenses, :time
    add_index :budget_expenses, :category
  end
end
