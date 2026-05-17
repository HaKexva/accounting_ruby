class ActualExpenditure < ApplicationRecord
  belongs_to :calendar_month, inverse_of: :actual_expenditures
  belongs_to :user, inverse_of: :actual_expenditures

  NULLIFY_OPTIONAL_STRINGS = %w[credit_card_payment_method payment_timing payment_platform].freeze

  before_validation :nullify_blank_optional_strings
  before_validation :clear_dependent_fields_unless_applicable

  validates :actual_amount, presence: true
  validates :posted_amount, presence: true
  validates :payment_method, presence: true
  validates :category, presence: true
  validates :transaction_item, presence: true
  validates :transaction_date, presence: true

  validate :payment_timing_required_for_credit_card
  validate :credit_card_payment_method_required_for_credit_card
  validate :payment_platform_required_for_multi_pay

  private

  def nullify_blank_optional_strings
    NULLIFY_OPTIONAL_STRINGS.each do |attr|
      v = self[attr]
      self[attr] = nil if v.is_a?(String) && v.blank?
    end
  end

  def clear_dependent_fields_unless_applicable
    unless payment_method.to_s.include?("信用卡")
      self.credit_card_payment_method = nil
      self.payment_timing = nil
    end

    return if payment_method.to_s == "多元支付"

    self.payment_platform = nil
  end

  def payment_timing_required_for_credit_card
    return unless payment_method.to_s.include?("信用卡")

    errors.add(:payment_timing, :blank) if payment_timing.blank?
  end

  def credit_card_payment_method_required_for_credit_card
    return unless payment_method.to_s.include?("信用卡")

    errors.add(:credit_card_payment_method, :blank) if credit_card_payment_method.blank?
  end

  def payment_platform_required_for_multi_pay
    return unless payment_method.to_s == "多元支付"

    errors.add(:payment_platform, :blank) if payment_platform.blank?
  end
end
