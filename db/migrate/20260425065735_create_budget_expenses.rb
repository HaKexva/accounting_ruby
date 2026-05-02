class CreateBudgetExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenditure_budgets do |t|
      t.string :category, null: false
      t.string :item, null: false
      t.decimal :amount, null: false
      t.text :note

      t.timestamps
    end
  end
end
