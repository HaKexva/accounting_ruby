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
  PAGE_TITLE_CLASS = "text-balance text-2xl font-semibold tracking-tight sm:text-3xl"
  PAGE_NARROW_CLASS = "mx-auto w-full max-w-3xl flex flex-col gap-4 sm:gap-6"

  MONTH_SUMMARY_SECTION_CLASS = [
    "flex shrink-0 flex-col rounded-xl border bg-card text-card-foreground shadow-sm ring-1 ring-border/40",
    "min-h-0"
  ].join(" ")
  MONTH_SUMMARY_HEADER_CLASS = "border-b px-4 py-3"
  MONTH_SUMMARY_TITLE_CLASS = "text-sm font-medium"
  MONTH_SUMMARY_PERIOD_CLASS = "text-xs text-muted-foreground tabular-nums"
  MONTH_SUMMARY_BODY_CLASS = "flex flex-col gap-4 p-4 sm:gap-5 sm:p-5"
  MONTH_SUMMARY_STATS_ROW_CLASS = [
    "flex w-full flex-row flex-wrap justify-center gap-2 sm:gap-3",
    "lg:flex-col lg:flex-nowrap lg:items-stretch"
  ].join(" ")

  STAT_CHIP_CLASS = [
    "flex min-w-0 flex-1 basis-[calc(50%-0.25rem)] flex-col items-center rounded-lg border border-border/50",
    "bg-muted/25 px-2 py-2 text-center leading-tight sm:basis-auto sm:px-3",
    "lg:w-full lg:flex-none lg:basis-auto"
  ].join(" ")

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
    "mx-auto flex w-full max-w-full shrink-0 flex-col gap-2 rounded-lg border border-border/50 bg-muted/20 p-2",
    "sm:p-3"
  ].join(" ")
  CHART_CANVAS_WRAP_CLASS = [
    "relative mx-auto aspect-square w-full min-h-[10rem] min-w-0",
    "max-w-[12rem] sm:max-w-[13.5rem] sm:min-h-[11rem]"
  ].join(" ")

  PAGE_HEADER_ROW_CLASS = "flex flex-row items-start justify-between gap-4 shrink-0"

  CARD_SECTION_CLASS = [
    "rounded-xl border bg-card text-card-foreground shadow-sm ring-1 ring-border/40",
    "shrink-0"
  ].join(" ")

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
