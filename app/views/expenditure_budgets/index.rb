# frozen_string_literal: true

class Views::ExpenditureBudget::Index < Views::Base
  def view_template
    div(class: "space-y-4") do
      h1(class: "text-2xl font-semibold tracking-tight") { "Expenditure budgets" }
      render Views::PlaceholderPanel.new(
        heading: "Expenditure budgets",
        hint: "Planned spending by period will go here."
      )
    end
  end
end
