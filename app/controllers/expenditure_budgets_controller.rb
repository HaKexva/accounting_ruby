# frozen_string_literal: true

class ExpenditureBudgetsController < ApplicationController
  def index
    render Views::ExpenditureBudget::Index.new
  end
end
