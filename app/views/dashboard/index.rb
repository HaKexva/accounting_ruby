# frozen_string_literal: true

class Views::Dashboard::Index < Views::Base
  def view_template
    div(class: "space-y-4") do
      h1(class: "text-2xl font-semibold tracking-tight") { "Actual expenditure" }
      render Views::PlaceholderPanel.new(
        heading: "Actual expenditure is your dashboard.",
        hint: "Charts and tables for recorded spending will go here."
      )
    end
  end
end
