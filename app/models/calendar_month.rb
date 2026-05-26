class CalendarMonth < ApplicationRecord
  has_many :revenue_budgets, class_name: "RevenueBudget", inverse_of: :calendar_month, dependent: :destroy
  has_many :expenditure_budgets, class_name: "ExpenditureBudget", inverse_of: :calendar_month, dependent: :destroy
  has_many :actual_expenditures, class_name: "ActualExpenditure", inverse_of: :calendar_month, dependent: :destroy

  validates :month, presence: true,
                    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, uniqueness: { scope: :year }

  def self.for_year_month!(year, month)
    find_or_create_by!(year: year, month: month)
  end

  # Year/month of the calendar month immediately after the given pair.
  def self.following_year_month(year, month)
    if month == 12
      [ year + 1, 1 ]
    else
      [ year, month + 1 ]
    end
  end

  # Ensures the month after +reference_date+ exists so budgets can be entered early.
  def self.ensure_next_month_exists!(reference_date: Time.zone.today)
    next_year, next_month = following_year_month(reference_date.year, reference_date.month)
    for_year_month!(next_year, next_month)
  end
end
