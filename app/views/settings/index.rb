# frozen_string_literal: true

class Views::Settings::Index < Views::Base
  def view_template
    div(class: "space-y-4") do
      h1(class: "text-2xl font-semibold tracking-tight") { "設定" }
      render Views::PlaceholderPanel.new(
        heading: "設定",
        hint: "之後會在此顯示偏好與帳號相關選項。"
      )
    end
  end
end
