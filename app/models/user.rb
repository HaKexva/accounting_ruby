class User < ApplicationRecord
  has_many :revenue_budgets, class_name: "RevenueBudget", inverse_of: :user, dependent: :destroy
  has_many :expenditure_budgets, class_name: "ExpenditureBudget", inverse_of: :user, dependent: :destroy
  has_many :actual_expenditures, class_name: "ActualExpenditure", inverse_of: :user, dependent: :destroy
  has_many :expenditure_taxonomy_items, dependent: :destroy

  validates :google_uid, presence: true
  validates :email, presence: true
end
