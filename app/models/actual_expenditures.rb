class ActualExpenditure < ApplicationRecord
  belongs_to :calendar_month, inverse_of: :actual_expenditures
  belongs_to :user, inverse_of: :actual_expenditures

  NULLIFY_OPTIONAL_STRINGS = %w[credit_card_payment_method payment_timing payment_platform].freeze

  before_validation :default_transaction_item_from_category
  before_validation :nullify_blank_optional_strings
  before_validation :clear_card_only_fields_unless_credit_card

  validates :actual_amount, presence: true
  validates :category, presence: true
  validates :transaction_item, presence: true
  validates :transaction_date, presence: true

  validate :payment_timing_required_for_credit_card

  private

  def default_transaction_item_from_category
    self.transaction_item = category if transaction_item.blank? && category.present?
  end

  def nullify_blank_optional_strings
    NULLIFY_OPTIONAL_STRINGS.each do |attr|
      v = self[attr]
      self[attr] = nil if v.is_a?(String) && v.blank?
    end
  end

  def clear_card_only_fields_unless_credit_card
    return if payment_method.to_s.include?("信用卡")

    self.credit_card_payment_method = nil
    self.payment_timing = nil
  end

  def payment_timing_required_for_credit_card
    return unless payment_method.to_s.include?("信用卡")

    errors.add(:payment_timing, :blank) if payment_timing.blank?
  end
end
