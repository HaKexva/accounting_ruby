# frozen_string_literal: true

class RevenueBudgetsController < ApplicationController
  def index
    render Views::RevenueBudget::Index.new
  end
end
