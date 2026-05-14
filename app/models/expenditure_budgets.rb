class ExpenditureBudget < ApplicationRecord
  belongs_to :calendar_month, inverse_of: :expenditure_budgets
  belongs_to :user, inverse_of: :expenditure_budgets

  before_validation :default_item_from_category

  validates :amount, presence: true
  validates :category, presence: true
  validates :item, presence: true

  private

  def default_item_from_category
    self.item = category if item.blank? && category.present?
  end
end
