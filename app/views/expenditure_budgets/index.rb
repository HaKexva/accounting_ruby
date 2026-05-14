# frozen_string_literal: true

class Views::ExpenditureBudget::Index < Views::Base
  def view_template
    div(class: "space-y-4") do
      h1(class: "text-2xl font-semibold tracking-tight") { "支出預算" }
      render Views::PlaceholderPanel.new(
        heading: "支出預算",
        hint: "之後會在此顯示依期間編列的支出預算。"
      )
    end
  end
end
