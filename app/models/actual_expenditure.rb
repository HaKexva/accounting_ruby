class ActualExpenditure < ApplicationRecord
  self.table_name = "actual_expenditure"

  belongs_to :calendar_month, inverse_of: :actual_expenditures
  belongs_to :user, inverse_of: :actual_expenditures
  validates :actual_amount, presence: true
  validates :category, presence: true
  validates :transaction_item, presence: true
  validates :transaction_date, presence: true
end
