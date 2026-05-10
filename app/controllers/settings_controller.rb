# frozen_string_literal: true

class SettingsController < ApplicationController
  def index
    render Views::Settings::Index.new
  end
end
