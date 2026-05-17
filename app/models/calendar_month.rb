class CalendarMonth < ApplicationRecord
  has_many :revenue_budgets, class_name: "RevenueBudget", inverse_of: :calendar_month, dependent: :destroy
  has_many :expenditure_budgets, class_name: "ExpenditureBudget", inverse_of: :calendar_month, dependent: :destroy
  has_many :actual_expenditures, class_name: "ActualExpenditure", inverse_of: :calendar_month, dependent: :destroy

  validates :month, presence: true,
                    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, uniqueness: { scope: :year }
end
