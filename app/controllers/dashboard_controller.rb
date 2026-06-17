# frozen_string_literal: true

class DashboardController < ApplicationController
  include CalendarMonthResolution

  HISTORY_SORTS = {
    "date_desc" => { transaction_date: :desc, id: :desc },
    "date_asc" => { transaction_date: :asc, id: :asc },
    "amount_desc" => { posted_amount: :desc, id: :desc },
    "amount_asc" => { posted_amount: :asc, id: :asc }
  }.freeze
  HISTORY_DEFAULT_SORT = "date_desc"

  def index
    user = trial_account_owner
    calendar_month = calendar_month_from_params
    month_choices = calendar_month_choices_for(user, selected: calendar_month)

    month_scope =
      if user
        ActualExpenditure.where(user: user, calendar_month: calendar_month)
      else
        ActualExpenditure.none
      end

    by_category = month_scope.group(:category).sum(:posted_amount)
    month_total = month_scope.sum(:actual_amount)
    month_count = month_scope.count

    budget_scope =
      if user
        ExpenditureBudget.where(user: user, calendar_month: calendar_month)
      else
        ExpenditureBudget.none
      end
    category_budgets = budget_scope.group(:category).sum(:amount)
    expenditure_budget_total = budget_scope.sum(:amount)

    revenue_scope =
      if user
        RevenueBudget.where(user: user, calendar_month: calendar_month)
      else
        RevenueBudget.none
      end
    revenue_total = revenue_scope.sum(:amount)

    taxonomy = ExpenditureTaxonomy.for_user(user)

    render Views::Dashboard::Index.new(
      calendar_month: calendar_month,
      month_choices: month_choices,
      month_total: month_total,
      month_count: month_count,
      category_amounts: by_category,
      category_budgets: category_budgets,
      expenditure_budget_total: expenditure_budget_total,
      revenue_total: revenue_total,
      taxonomy: taxonomy
    )
  end

  def history
    user = trial_account_owner
    month_filter = optional_calendar_month_from_params
    month_choices = calendar_month_choices_for(user, selected: month_filter)

    filters = history_filter_params
    q = filters[:q]
    category = filters[:category]
    payment_method = filters[:payment_method]
    payment_platform = filters[:payment_platform]
    date_from = parse_iso_date(filters[:date_from])
    date_to = parse_iso_date(filters[:date_to])
    min_amount = parse_decimal(filters[:min_posted_amount])
    max_amount = parse_decimal(filters[:max_posted_amount])

    expenditures =
      if user
        scope = ActualExpenditure.includes(:calendar_month).for_user(user)
        scope = scope.where(calendar_month: month_filter) if month_filter
        scope = scope.search_text(q)
        scope = scope.category_is(category) if category.present?
        scope = scope.payment_method_is(payment_method) if payment_method.present?
        scope = scope.payment_platform_is(payment_platform) if payment_platform.present?
        scope = scope.transaction_date_from(date_from) if date_from
        scope = scope.transaction_date_to(date_to) if date_to
        scope = scope.posted_amount_gte(min_amount) if min_amount
        scope = scope.posted_amount_lte(max_amount) if max_amount
        scope.order(**history_sort_order(filters[:sort]))
      else
        ActualExpenditure.none
      end
    taxonomy = ExpenditureTaxonomy.for_user(user)
    render Views::Dashboard::History.new(
      actual_expenditures: expenditures,
      month_filter: month_filter,
      month_choices: month_choices,
      taxonomy: taxonomy,
      filters: filters
    )
  end

  private

  def history_filter_params
    params.permit(:q, :category, :payment_method, :payment_platform, :date_from, :date_to,
                  :min_posted_amount, :max_posted_amount, :sort)
  end

  def history_sort_order(sort)
    key = sort.to_s
    key = HISTORY_DEFAULT_SORT unless HISTORY_SORTS.key?(key)
    HISTORY_SORTS.fetch(key)
  end

  def parse_iso_date(raw)
    return nil if raw.blank?

    Date.iso8601(raw.to_s)
  rescue ArgumentError
    nil
  end

  def parse_decimal(raw)
    s = raw.to_s.strip.delete(",").presence
    return nil if s.blank?

    BigDecimal(s)
  rescue ArgumentError
    nil
  end
end
