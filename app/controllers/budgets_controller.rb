# frozen_string_literal: true

class BudgetsController < ApplicationController
  def index
    render Views::Budgets::Index.new
  end
end
