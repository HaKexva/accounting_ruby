# frozen_string_literal: true

class Views::Budgets::Index < Views::Base
  def view_template
    div(class: "space-y-8") do
      div(class: "space-y-1") do
        h1(class: "text-2xl font-semibold tracking-tight") { "預算" }
        p(class: "text-sm text-muted-foreground") { "管理收入與支出預算。" }
      end

      div(class: "space-y-4") do
        h2(class: "text-lg font-semibold tracking-tight") { "收入預算" }
        render Views::PlaceholderPanel.new(
          heading: "收入預算",
          hint: "之後會在此顯示依期間編列的收入預算。"
        )
      end

      div(class: "space-y-4") do
        h2(class: "text-lg font-semibold tracking-tight") { "支出預算" }
        render Views::PlaceholderPanel.new(
          heading: "支出預算",
          hint: "之後會在此顯示依期間編列的支出預算。"
        )
      end
    end
  end
end
