# frozen_string_literal: true

class Views::Settings::Index < Views::Base
  def view_template
    div(class: "#{PAGE_SHELL} space-y-6") do
      div(class: "space-y-2 pb-2 border-b border-border/60") do
        h1(class: "text-balance text-2xl font-semibold tracking-tight sm:text-3xl") { "設定" }
        p(class: "max-w-prose text-sm leading-relaxed text-muted-foreground") do
          "應用程式偏好與帳號選項（開發中）。"
        end
      end
      render Views::PlaceholderPanel.new(
        heading: "尚未開放",
        hint: "之後會在此顯示偏好與帳號相關選項。"
      )
    end
  end
end
