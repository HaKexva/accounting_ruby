# frozen_string_literal: true

class Views::PlaceholderPanel < Views::Base
  def initialize(heading:, hint:)
    @heading = heading
    @hint = hint
  end

  def view_template
    div(class: "rounded-xl border border-dashed bg-muted/30 p-10 text-center") do
      p(class: "text-sm font-medium text-foreground") { @heading }
      p(class: "mt-2 text-sm text-muted-foreground") { @hint }
    end
  end
end
