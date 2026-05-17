# frozen_string_literal: true

class Views::PlaceholderPanel < Views::Base
  def initialize(heading:, hint:)
    @heading = heading
    @hint = hint
  end

  def view_template
    div(
      class: [
        "rounded-2xl border border-dashed border-border/70",
        "bg-gradient-to-br from-muted/35 via-card to-background",
        "px-8 py-14 text-center shadow-sm sm:px-12 sm:py-16"
      ].join(" ")
    ) do
      div(class: "mx-auto mb-4 flex size-12 items-center justify-center rounded-full bg-muted/50 text-muted-foreground") do
        plain "…"
      end
      p(class: "text-base font-semibold text-foreground") { @heading }
      p(class: "mx-auto mt-3 max-w-md text-sm leading-relaxed text-muted-foreground") { @hint }
    end
  end
end
