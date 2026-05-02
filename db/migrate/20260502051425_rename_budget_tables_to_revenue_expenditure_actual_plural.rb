class RenameBudgetTablesToRevenueExpenditureActualPlural < ActiveRecord::Migration[8.1]
  def up
    if table_exists?(:budget_incomes) && !table_exists?(:revenue_budgets)
      rename_table :budget_incomes, :revenue_budgets
    end
    if table_exists?(:budget_expenses) && !table_exists?(:expenditure_budgets)
      rename_table :budget_expenses, :expenditure_budgets
    end
    if table_exists?(:real_expenses) && !table_exists?(:actual_expenditures)
      rename_table :real_expenses, :actual_expenditures
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
