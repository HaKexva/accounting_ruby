class RevenueBudget < ApplicationRecord
  self.table_name = "revenue_budget"

  belongs_to :calendar_month, inverse_of: :revenue_budgets
  belongs_to :user, inverse_of: :revenue_budgets
  validates :amount, presence: true
  validates :item, presence: true
end
