# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    render Views::Dashboard::Index.new
  end

  def history
    expenditures = ActualExpenditure.includes(:calendar_month).order(transaction_date: :desc, id: :desc)
    render Views::Dashboard::History.new(actual_expenditures: expenditures)
  end
end
