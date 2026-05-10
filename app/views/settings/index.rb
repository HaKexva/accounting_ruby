# frozen_string_literal: true

class Views::Settings::Index < Views::Base
  def view_template
    div(class: "space-y-4") do
      h1(class: "text-2xl font-semibold tracking-tight") { "Settings" }
      render Views::PlaceholderPanel.new(
        heading: "Settings",
        hint: "Preferences and account options will go here."
      )
    end
  end
end
