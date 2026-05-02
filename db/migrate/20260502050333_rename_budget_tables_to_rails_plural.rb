class RenameBudgetTablesToRailsPlural < ActiveRecord::Migration[8.1]
  # Legacy installs created singular table names; newer migrations create plural directly.
  def up
    rename_table :revenue_budget, :revenue_budgets if table_exists?(:revenue_budget)
    rename_table :expenditure_budget, :expenditure_budgets if table_exists?(:expenditure_budget)
    rename_table :actual_expenditure, :actual_expenditures if table_exists?(:actual_expenditure)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
