# frozen_string_literal: true

class Views::RevenueBudget::Index < Views::Base
  def view_template
    div(class: "space-y-4") do
      h1(class: "text-2xl font-semibold tracking-tight") { "收入預算" }
      render Views::PlaceholderPanel.new(
        heading: "收入預算",
        hint: "之後會在此顯示依期間編列的收入預算。"
      )
    end
  end
end
