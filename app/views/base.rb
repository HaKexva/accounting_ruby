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

  # Shared chrome for 實際支出 / 預算 (keep both pages visually aligned).
  PAGE_TITLE_CLASS = "text-balance text-2xl font-semibold tracking-tight text-foreground sm:text-3xl"
  PAGE_LEAD_CLASS = "max-w-prose text-sm leading-relaxed text-muted-foreground"
  PAGE_HEADER_BLOCK_CLASS = "flex flex-row items-start justify-between gap-4 shrink-0"
  PAGE_NARROW_CLASS = "mx-auto w-full max-w-3xl flex flex-col gap-5 sm:gap-6"

  MONTH_SUMMARY_SECTION_CLASS = [
    "flex shrink-0 flex-col rounded-xl border border-border/80 bg-card text-card-foreground",
    "shadow-sm shadow-black/[0.04] ring-1 ring-border/50",
    "min-h-0"
  ].join(" ")
  MONTH_SUMMARY_HEADER_CLASS = "border-b border-border/60 bg-muted/20 px-4 py-3.5 sm:px-5"
  MONTH_SUMMARY_TITLE_CLASS = "text-sm font-semibold text-foreground"
  MONTH_SUMMARY_PERIOD_CLASS = "text-xs text-muted-foreground tabular-nums"
  MONTH_SUMMARY_BODY_CLASS = "flex flex-col gap-4 p-4 sm:gap-5 sm:p-5"
  MONTH_SUMMARY_STATS_ROW_CLASS = [
    "flex w-full flex-row flex-wrap justify-center gap-2 sm:gap-3",
    "lg:flex-col lg:flex-nowrap lg:items-stretch"
  ].join(" ")

  STAT_CHIP_BASE_CLASS = [
    "flex min-w-0 flex-1 basis-[calc(50%-0.25rem)] flex-col items-center rounded-xl border px-2.5 py-2.5",
    "text-center leading-tight shadow-sm sm:basis-auto sm:px-3.5 sm:py-3",
    "lg:w-full lg:flex-none lg:basis-auto"
  ].join(" ")

  STAT_CHIP_ACCENTS = {
    budget: "border-chart-2/35 bg-chart-2/10",
    expense: "border-destructive/30 bg-destructive/[0.06]",
    remain: "border-emerald-500/35 bg-emerald-500/[0.08]"
  }.freeze

  PAGE_SPLIT_GRID_CLASS = [
    "flex min-h-0 flex-1 flex-col",
    "lg:grid lg:grid-cols-2 lg:items-start lg:gap-6 xl:gap-8 lg:pt-2"
  ].join(" ")

  PAGE_SPLIT_LEFT_STICKY_CLASS = [
    PAGE_TOP_STICKY,
    "!space-y-2 !pb-2 sm:!space-y-2 sm:!pb-3",
    "max-h-[min(35svh,20rem)] sm:max-h-[38svh]",
    "min-h-0 flex flex-col overflow-hidden",
    "border-border/40 bg-background/90",
    "lg:sticky lg:top-4 lg:z-[1] lg:self-start lg:max-h-[calc(100dvh-6rem)] lg:overflow-y-auto lg:pr-1",
    "lg:border-0 lg:bg-transparent lg:backdrop-blur-none lg:supports-[backdrop-filter]:bg-transparent",
    "lg:mx-0 lg:px-0 lg:!space-y-0 lg:!pb-0"
  ].join(" ")

  PAGE_SPLIT_RIGHT_BODY_CLASS = [
    PAGE_BODY_BELOW_STICKY,
    "!gap-4 !pt-1 sm:!gap-5 sm:!pt-2",
    "!pb-3 sm:!pb-4",
    "min-w-0 flex flex-col",
    "lg:gap-0 lg:pt-0 lg:!pb-0 lg:min-h-0 lg:max-h-[calc(100dvh-6rem)] lg:overflow-y-auto lg:pl-1"
  ].join(" ")
  STAT_CHIP_LABEL_CLASS = "text-[10px] font-medium text-muted-foreground sm:text-xs"
  STAT_CHIP_VALUE_CLASS = "mt-1 text-sm font-semibold tabular-nums text-foreground sm:text-base"
  STAT_CHIP_META_CLASS = "mt-0.5 text-[10px] tabular-nums text-muted-foreground sm:text-xs"

  CHART_PANEL_CLASS = [
    "mx-auto flex w-full max-w-full shrink-0 flex-col gap-2 rounded-xl border border-border/60",
    "bg-gradient-to-b from-muted/30 to-muted/10 p-2.5 sm:p-3.5"
  ].join(" ")
  CHART_CANVAS_WRAP_CLASS = [
    "relative mx-auto aspect-square w-full min-h-[10rem] min-w-0",
    "max-w-[12rem] sm:max-w-[13.5rem] sm:min-h-[11rem]"
  ].join(" ")

  PAGE_HEADER_ROW_CLASS = "flex flex-row items-start justify-between gap-4 shrink-0"

  CARD_SECTION_CLASS = [
    "rounded-xl border border-border/80 bg-card text-card-foreground",
    "shadow-sm shadow-black/[0.04] ring-1 ring-border/50",
    "shrink-0"
  ].join(" ")

  SEGMENTED_CONTROL_CLASS = [
    "relative inline-flex w-full max-w-md rounded-lg border border-border/70",
    "bg-muted/50 p-1 shadow-inner sm:w-auto"
  ].join(" ")
  SEGMENTED_CONTROL_INDICATOR_CLASS = [
    "pointer-events-none absolute inset-y-1 left-1 z-0 rounded-md",
    "bg-card shadow-sm ring-1 ring-border/60",
    "transition-[transform,width] duration-200 ease-out will-change-transform"
  ].join(" ")
  SEGMENTED_CONTROL_BTN_CLASS = [
    "relative z-10 flex-1 rounded-md px-3 py-2 text-center text-sm font-medium",
    "transition-colors text-muted-foreground hover:text-foreground",
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
    "focus-visible:ring-offset-2 focus-visible:ring-offset-background"
  ].join(" ")
  SEGMENTED_CONTROL_BTN_ACTIVE_CLASS = "text-foreground"

  def page_header(title:, subtitle: nil)
    div(class: PAGE_HEADER_BLOCK_CLASS) do
      div(class: "min-w-0 flex-1 space-y-1 pr-2") do
        h1(class: PAGE_TITLE_CLASS) { title }
        p(class: PAGE_LEAD_CLASS) { subtitle } if subtitle.present?
      end
      if block_given?
        div(class: "flex shrink-0 items-center gap-2 self-start pt-0.5") { yield }
      end
    end
  end

  def stat_chip_class(accent: nil)
    accent_key = accent&.to_sym
    accent_classes = STAT_CHIP_ACCENTS.fetch(accent_key, "border-border/50 bg-muted/30")
    "#{STAT_CHIP_BASE_CLASS} #{accent_classes}"
  end

  def calendar_month_label_for(calendar_month)
    if calendar_month
      "#{calendar_month.year} 年 #{calendar_month.month} 月"
    else
      t = Time.zone.today
      "#{t.year} 年 #{t.month} 月"
    end
  end

  # More caching options at https://www.phlex.fun/components/caching
  def cache_store = Rails.cache
end
