# frozen_string_literal: true

class Views::PlaceholderPanel < Views::Base
  def initialize(heading:, hint:)
    @heading = heading
    @hint = hint
  end

  def view_template
    div(
      class: [
        "rounded-2xl border-2 border-dashed border-border/60 bg-gradient-to-br from-muted/40 via-muted/15 to-background",
        "px-8 py-14 text-center shadow-sm sm:px-12 sm:py-16"
      ].join(" ")
    ) do
      p(class: "text-base font-semibold text-foreground") { @heading }
      p(class: "mx-auto mt-3 max-w-md text-sm leading-relaxed text-muted-foreground") { @hint }
    end
  end
end
