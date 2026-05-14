# frozen_string_literal: true

class Views::Dashboard::History < Views::Base
  def view_template
    div(class: "space-y-4") do
      div(class: "flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between") do
        h1(class: "text-2xl font-semibold tracking-tight") { "歷史紀錄" }
        Link(href: root_path, variant: :outline, size: :md) { "返回實際支出" }
      end
      render Views::PlaceholderPanel.new(
        heading: "歷史紀錄",
        hint: "之後會在此顯示過往支出列表與篩選。"
      )
    end
  end
end
