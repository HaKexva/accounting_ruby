# frozen_string_literal: true

class ExpenseHistoryQuery
  SORTS = {
    "date_desc" => { transaction_date: :desc, id: :desc },
    "date_asc" => { transaction_date: :asc, id: :asc },
    "amount_desc" => { posted_amount: :desc, id: :desc },
    "amount_asc" => { posted_amount: :asc, id: :asc }
  }.freeze
  DEFAULT_SORT = "date_desc"

  SORT_LABELS = {
    "date_desc" => "日期（新→舊）",
    "date_asc" => "日期（舊→新）",
    "amount_desc" => "金額（高→低）",
    "amount_asc" => "金額（低→高）"
  }.freeze

  class Filters
    attr_reader :category, :payment_method, :month, :q, :sort

    def self.from_params(params, taxonomy:)
      sort = params[:sort].to_s
      sort = DEFAULT_SORT unless SORTS.key?(sort)

      new(
        category: pick_allowed(params[:category], taxonomy.categories),
        payment_method: pick_allowed(params[:payment_method], taxonomy.payment_methods),
        month: valid_month_param(params[:month]),
        q: params[:q].to_s.strip.presence,
        sort: sort
      )
    end

    def self.pick_allowed(value, allowed)
      name = value.to_s.strip
      return nil if name.blank?

      allowed.include?(name) ? name : nil
    end

    def self.valid_month_param(value)
      token = value.to_s.strip
      return nil unless token.match?(/\A\d{4}-\d{2}-\z/)

      year, month = token.split("-").map(&:to_i)
      return nil if month < 1 || month > 12

      token
    end

    def initialize(category:, payment_method:, month:, q:, sort:)
      @category = category
      @payment_method = payment_method
      @month = month
      @q = q
      @sort = sort
    end

    def active?
      category.present? || payment_method.present? || month.present? || q.present?
    end
  end

  def initialize(scope:, filters:)
    @scope = scope
    @filters = filters
  end

  def call
    apply_filters(@scope).order(SORTS.fetch(@filters.sort))
  end

  private

  def apply_filters(scope)
    scope = scope.where(category: @filters.category) if @filters.category.present?
    scope = scope.where(payment_method: @filters.payment_method) if @filters.payment_method.present?

    if @filters.month.present?
      year, month = @filters.month.split("-").map(&:to_i)
      scope = scope.joins(:calendar_month).where(calendar_months: { year: year, month: month })
    end

    if @filters.q.present?
      escaped = ActiveRecord::Base.sanitize_sql_like(@filters.q)
      scope = scope.where("transaction_item LIKE ?", "%#{escaped}%")
    end

    scope
  end
end
