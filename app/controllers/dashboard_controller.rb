# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    user = trial_account_owner
    today = Time.zone.today
    calendar_month = CalendarMonth.find_or_create_by!(year: today.year, month: today.month)

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
      month_total: month_total,
      month_count: month_count,
      category_amounts: by_category,
      category_budgets: category_budgets,
      revenue_total: revenue_total,
      taxonomy: taxonomy
    )
  end

  def history
    user = trial_account_owner
    taxonomy = ExpenditureTaxonomy.for_user(user)
    base_scope =
      if user
        ActualExpenditure.includes(:calendar_month).where(user: user)
      else
        ActualExpenditure.none
      end

    filters = ExpenseHistoryQuery::Filters.from_params(params, taxonomy: taxonomy)
    expenditures = ExpenseHistoryQuery.new(scope: base_scope, filters: filters).call
    month_options = history_month_options(user)

    render Views::Dashboard::History.new(
      actual_expenditures: expenditures,
      taxonomy: taxonomy,
      filters: filters,
      month_options: month_options,
      total_unfiltered: base_scope.count
    )
  end

  private

  def history_month_options(user)
    return [] unless user

    CalendarMonth
      .joins(:actual_expenditures)
      .where(actual_expenditures: { user_id: user.id })
      .distinct
      .order(year: :desc, month: :desc)
      .pluck(:year, :month)
      .map { |year, month| [ format_history_month(year, month), format("%04d-%02d", year, month) ] }
  end

  def format_history_month(year, month)
    "#{year} 年 #{month} 月"
  end
end
