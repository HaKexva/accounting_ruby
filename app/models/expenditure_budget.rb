class ExpenditureBudget < ApplicationRecord
  self.table_name = "expenditure_budget"

  belongs_to :calendar_month, inverse_of: :expenditure_budgets
  belongs_to :user, inverse_of: :expenditure_budgets
  validates :amount, presence: true
  validates :category, presence: true
  validates :item, presence: true
end
