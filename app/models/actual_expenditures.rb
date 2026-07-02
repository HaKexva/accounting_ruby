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

  scope :for_user, ->(user) { where(user: user) }
  scope :in_calendar_month, ->(calendar_month) { where(calendar_month: calendar_month) }
  scope :category_is, ->(category) { where(category: category) }
  scope :payment_method_is, ->(payment_method) { where(payment_method: payment_method) }
  scope :payment_platform_is, ->(payment_platform) { where(payment_platform: payment_platform) }
  scope :transaction_date_from, ->(date) { where("transaction_date >= ?", date) }
  scope :transaction_date_to, ->(date) { where("transaction_date <= ?", date) }
  scope :posted_amount_gte, ->(amount) { where("posted_amount >= ?", amount) }
  scope :posted_amount_lte, ->(amount) { where("posted_amount <= ?", amount) }
  scope :search_text, lambda { |q|
    t = q.to_s.strip
    next all if t.blank?

    pattern = "%#{sanitize_sql_like(t)}%"
    adapter = connection.adapter_name.to_s.downcase
    like_op = adapter.include?("postgres") ? "ILIKE" : "LIKE"
    where(
      "transaction_item #{like_op} :pattern OR note #{like_op} :pattern OR category #{like_op} :pattern",
      pattern: pattern
    )
  }

  # Human-readable 支出方式 for lists (method + card/platform details).
  def payment_summary
    method_name = payment_method.to_s.strip
    return nil if method_name.blank?

    parts = [ method_name ]
    if method_name.include?("信用卡")
      parts << credit_card_payment_method if credit_card_payment_method.present?
      parts << payment_timing if payment_timing.present?
    elsif payment_method_requires_platform?
      parts << payment_platform if payment_platform.present?
    end
    parts.join(" · ")
  end

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

    return if payment_method_requires_platform?

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
    return unless payment_method_requires_platform?

    errors.add(:payment_platform, :blank) if payment_platform.blank?
  end

  def payment_method_requires_platform?
    method_name = payment_method.to_s.strip
    return false if method_name.blank?

    if ExpenditureTaxonomy.persisted_taxonomy_available? && user
      methods = user.expenditure_taxonomy_items.for_kind("payment_method")
      if methods.exists?
        return methods.where(requires_payment_platform: true)
                      .where("LOWER(name) = LOWER(?)", method_name)
                      .exists?
      end
    end

    ExpenditureTaxonomy.default_payment_methods_requiring_platform.any? do |name|
      name.casecmp?(method_name)
    end
  end
end
