# frozen_string_literal: true

class Views::RevenueBudget::Index < Views::Base
  def view_template
    div(class: "space-y-4") do
      h1(class: "text-2xl font-semibold tracking-tight") { "Revenue budgets" }
      render Views::PlaceholderPanel.new(
        heading: "Revenue budgets",
        hint: "Planned revenue by period will go here."
      )
    end
  end
end
