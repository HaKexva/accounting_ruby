# frozen_string_literal: true

class Views::Base < Components::Base
  # The `Views::Base` is an abstract class for all your views.

  # By default, it inherits from `Components::Base`, but you
  # can change that to `Phlex::HTML` if you want to keep views and
  # components independent.

  # Full width within the layout content column (`RubyUI::Layout` applies `max-w-6xl mx-auto`).
  PAGE_SHELL = "flex min-h-0 w-full flex-col"

  PAGE_TOP_STICKY = [
    "sticky top-0 z-10 shrink-0 space-y-6 pb-6",
    "border-b border-border/60",
    "-mx-1 px-1 backdrop-blur-md supports-[backdrop-filter]:bg-background/80 bg-background/95"
  ].join(" ")

  PAGE_BODY_BELOW_STICKY = "shrink-0 flex flex-col gap-8 pt-8"

  # More caching options at https://www.phlex.fun/components/caching
  def cache_store = Rails.cache
end
