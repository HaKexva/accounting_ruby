class RenameBudgetTablesToMatchModels < ActiveRecord::Migration[8.1]
  # Former intermediate rename toward budget_* table names. Final naming uses
  # revenue_budgets / expenditure_budgets / actual_expenditures (see migration
  # RenameBudgetTablesToRevenueExpenditureActualPlural). Kept as no-op for environments
  # that already recorded this version.

  def up
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
