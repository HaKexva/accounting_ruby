# frozen_string_literal: true

# When a taxonomy label is renamed in settings, update denormalized name columns
# on that user's expenditures and budgets (including expense history).
class ExpenditureTaxonomyRenamePropagator
  COLUMN_MAPPINGS = {
    "category" => [
      [ ActualExpenditure, :category ],
      [ ExpenditureBudget, :category ]
    ],
    "payment_method" => [
      [ ActualExpenditure, :payment_method ]
    ],
    "payment_platform" => [
      [ ActualExpenditure, :payment_platform ]
    ]
  }.freeze

  def self.call(user:, kind:, from:, to:)
    new(user: user, kind: kind, from: from, to: to).call
  end

  def initialize(user:, kind:, from:, to:)
    @user = user
    @kind = kind.to_s
    @from = from.to_s
    @to = to.to_s
  end

  def call
    return 0 if @user.blank? || @from.blank? || @to.blank? || @from == @to

    mappings = COLUMN_MAPPINGS[@kind]
    return 0 if mappings.blank?

    mappings.sum do |model, column|
      model.where(user: @user)
           .where(column => @from)
           .update_all(column => @to, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
