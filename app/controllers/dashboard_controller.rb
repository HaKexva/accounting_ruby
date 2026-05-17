# frozen_string_literal: true

class DashboardController < ApplicationController
  include TrialAccount

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

    by_category = month_scope.group(:category).sum(:actual_amount)
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

    render Views::Dashboard::Index.new(
      calendar_month: calendar_month,
      month_total: month_total,
      month_count: month_count,
      category_amounts: by_category,
      category_budgets: category_budgets,
      revenue_total: revenue_total
    )
  end

  def history
    user = trial_account_owner
    expenditures =
      if user
        ActualExpenditure.includes(:calendar_month).where(user: user)
          .order(transaction_date: :desc, id: :desc)
      else
        ActualExpenditure.none
      end
    render Views::Dashboard::History.new(actual_expenditures: expenditures)
  end
end
