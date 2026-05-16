# frozen_string_literal: true

class BudgetsController < ApplicationController
  def index
    user = User.order(:id).first
    today = Time.zone.today
    calendar_month = nil
    revenue_budgets = []
    expenditure_budgets = []

    if user
      calendar_month = CalendarMonth.find_or_create_by!(user: user, year: today.year, month: today.month)
      revenue_budgets = RevenueBudget.where(calendar_month: calendar_month).order(:id).to_a
      expenditure_budgets = ExpenditureBudget.where(calendar_month: calendar_month).order(:id).to_a
    end

    render Views::Budgets::Index.new(
      revenue_budgets: revenue_budgets,
      expenditure_budgets: expenditure_budgets,
      calendar_month: calendar_month
    )
  end
end
