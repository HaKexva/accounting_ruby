# frozen_string_literal: true

class ExpenditureTaxonomyItem < ApplicationRecord
  KINDS = %w[category payment_method payment_platform].freeze

  KIND_LABELS = {
    "category" => "消費類別",
    "payment_method" => "支付方式",
    "payment_platform" => "支付平台"
  }.freeze

  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  validates :name, presence: true
  validates :name, uniqueness: { scope: %i[user_id kind], case_sensitive: false }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
  scope :for_kind, ->(kind) { where(kind: kind).ordered }

  before_validation :normalize_name
  before_validation :clear_requires_payment_platform_unless_payment_method

  private

  def normalize_name
    self.name = name.to_s.strip if name
  end

  def clear_requires_payment_platform_unless_payment_method
    self.requires_payment_platform = false unless kind == "payment_method"
  end
end
