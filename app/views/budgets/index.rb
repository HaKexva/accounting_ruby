# frozen_string_literal: true

class Views::Budgets::Index < Views::Base
  def initialize(revenue_budgets:, expenditure_budgets:, calendar_month:)
    @revenue_budgets = revenue_budgets
    @expenditure_budgets = expenditure_budgets
    @calendar_month = calendar_month
  end

  def view_template
    div(class: PAGE_SHELL) do
      div(class: PAGE_TOP_STICKY) do
        budget_header_row
        budget_month_summary_panel
      end

      div(class: PAGE_BODY_BELOW_STICKY) do
        div(class: "w-full", data: { controller: "budgets-kind" }) do
          div(data: { budgets_kind_target: "revenuePanel" }) do
            revenue_budget_deck
          end

          div(class: "hidden", data: { budgets_kind_target: "expenditurePanel" }) do
            expenditure_budget_deck
          end
        end

        budget_footer_hint
      end
    end
  end

  private

  def revenue_budget_deck
    slides = @revenue_budgets.empty? ? [ nil ] : @revenue_budgets
    budget_deck_wrapper do
      budget_kind_toolbar(select_suffix: "revenue_deck")
      Carousel(
        tabindex: "0",
        options: { loop: false },
        class: [
          "w-full rounded-none outline-none bg-card",
          "focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "focus-visible:ring-offset-background"
        ].join(" "),
        aria: { label: "收入預算：左右切換多筆資料" }
      ) do
        CarouselPrevious
        CarouselContent do
          slides.each_with_index do |record, idx|
            CarouselItem { revenue_budget_slide(record, index: idx + 1, total: slides.size) }
          end
        end
        CarouselNext
      end
    end
  end

  def expenditure_budget_deck
    slides = @expenditure_budgets.empty? ? [ nil ] : @expenditure_budgets
    budget_deck_wrapper do
      budget_kind_toolbar(select_suffix: "expenditure_deck")
      Carousel(
        tabindex: "0",
        options: { loop: false },
        class: [
          "w-full rounded-none outline-none bg-card",
          "focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "focus-visible:ring-offset-background"
        ].join(" "),
        aria: { label: "支出預算：左右切換多筆資料" }
      ) do
        CarouselPrevious
        CarouselContent do
          slides.each_with_index do |record, idx|
            CarouselItem { expenditure_budget_slide(record, index: idx + 1, total: slides.size) }
          end
        end
        CarouselNext
      end
    end
  end

  def budget_deck_wrapper(&)
    div(class: "relative w-full") do
      div(class: "overflow-hidden rounded-xl border bg-card text-card-foreground shadow-sm ring-1 ring-border/40") do
        yield
      end
    end
  end

  def budget_kind_toolbar(select_suffix:)
    div(class: "flex flex-wrap items-center gap-x-2 gap-y-2 border-b border-border px-3 py-3 sm:px-4 sm:py-3") do
      span(class: "text-base font-semibold tracking-tight text-foreground sm:text-lg") { "新增" }
      div(
        class: [
          "min-w-[10rem] max-w-full shrink-0 sm:max-w-[min(14rem,calc(100vw-6rem))]",
          "[&>div]:w-full sm:[&>div]:w-auto",
          "[&_select]:min-h-11 [&_select]:py-2 sm:[&_select]:min-h-9 sm:[&_select]:py-1"
        ].join(" ")
      ) do
        NativeSelect(
          id: "budget_kind_select_#{select_suffix}",
          aria: { label: "預算類型：收入或支出（與「新增」同一列）" },
          data: {
            budgets_kind_target: "kindSelect",
            action: "change->budgets-kind#sync"
          }
        ) do
          NativeSelectOption(value: "revenue", selected: true) { plain "收入預算" }
          NativeSelectOption(value: "expenditure") { plain "支出預算" }
        end
      end
    end
  end

  def budget_header_row
    div(class: "flex flex-row items-start justify-between gap-4 shrink-0") do
      div(class: "min-w-0 flex-1 space-y-2 pr-2") do
        h1(class: "text-balance text-2xl font-semibold tracking-tight sm:text-3xl") { "預算" }
        p(class: "max-w-prose text-sm leading-relaxed text-muted-foreground") { "檢視與登錄預算。" }
      end
      div(class: "flex shrink-0 pt-0.5") { }
    end
  end

  def budget_month_summary_panel
    section(
      class: [
        "flex shrink-0 flex-col rounded-xl border bg-card text-card-foreground shadow-sm ring-1 ring-border/40",
        "min-h-[12rem]"
      ].join(" "),
      aria: { label: "本月預算資料" }
    ) do
      div(class: "border-b px-4 py-3") do
        div(class: "flex flex-col gap-0.5 sm:flex-row sm:items-baseline sm:justify-between") do
          h2(class: "text-sm font-medium") { "本月預算" }
          span(class: "text-xs text-muted-foreground tabular-nums") { current_month_label }
        end
      end
      div(class: "flex flex-col gap-5 p-4 sm:p-6") do
        p(class: "rounded-lg border border-border/50 bg-muted/25 px-3 py-2 text-sm leading-relaxed text-muted-foreground") do
          "此區顯示本月收入／支出預算合計與摘要（之後接上資料庫）。"
        end
      end
    end
  end

  def budget_footer_hint
    p(
      class: [
        "w-full rounded-xl border border-border/60 bg-muted/30 px-4 py-3 text-center text-[11px]",
        "leading-relaxed text-muted-foreground sm:text-xs"
      ].join(" ")
    ) do
      plain "頁面上方「本月預算」為統計預留區；卡片內為「新增」與類型選單，以及可滑動或箭頭切換的同類型多筆預算。"
    end
  end

  def revenue_budget_slide(record, index:, total:)
    suffix = record ? "rev_#{record.id}" : "rev_new"
    title = record&.item.presence || "新增收入預算"
    aria = total > 1 ? "#{title}（第 #{index} 筆／共 #{total} 筆）" : title

    section(
      class: [
        "flex min-h-[min(26rem,70svh)] flex-col bg-transparent",
        "sm:min-h-[min(30rem,76svh)]"
      ].join(" "),
      aria: { label: aria }
    ) do
      revenue_slide_header(index: index, total: total, record: record)
      div(class: "flex flex-1 flex-col gap-5 p-4 sm:gap-4 sm:p-6") do
        if (hint = revenue_slide_hint(record))
          p(class: "text-sm leading-relaxed text-muted-foreground") { hint }
        end
        div(class: "flex-1 border-t border-border/60 pt-5 sm:pt-5") do
          revenue_budget_form(record, suffix: suffix)
        end
      end
    end
  end

  def revenue_slide_hint(record)
    return unless record

    "NT$#{format_decimal(record.amount)} · 此筆已存入資料庫；表單僅供預覽／之後接上更新。"
  end

  def revenue_slide_header(index:, total:, record:)
    div(class: "border-b px-3 pb-3 pt-3 sm:px-4 sm:pb-3 sm:pt-4") do
      if total > 1
        p(class: "mb-2 text-[11px] font-medium tabular-nums text-muted-foreground sm:text-xs") do
          plain "第 #{index} 筆／共 #{total} 筆"
        end
      end
      div(class: "flex flex-row items-start justify-between gap-3") do
        div(class: "min-w-0 flex-1 pr-12 sm:pr-14") do
          if record
            p(class: "text-sm font-semibold leading-snug text-foreground") { record.item }
          end
          span(class: budget_month_label_class(record)) do
            current_month_label
          end
        end
        time(
          class: "shrink-0 text-xs tabular-nums text-muted-foreground sm:text-[13px]",
          data: { controller: "local-clock" }
        )
      end
    end
  end

  def expenditure_budget_slide(record, index:, total:)
    suffix = record ? "exp_#{record.id}" : "exp_new"
    title = record&.category.presence || record&.item.presence || "新增支出預算"
    aria = total > 1 ? "#{title}（第 #{index} 筆／共 #{total} 筆）" : title

    section(
      class: [
        "flex min-h-[min(26rem,70svh)] flex-col bg-transparent",
        "sm:min-h-[min(30rem,76svh)]"
      ].join(" "),
      aria: { label: aria }
    ) do
      expenditure_slide_header(index: index, total: total, record: record)
      div(class: "flex flex-1 flex-col gap-5 p-4 sm:gap-4 sm:p-6") do
        p(class: "text-sm leading-relaxed text-muted-foreground") { expenditure_slide_hint(record) }
        div(class: "flex-1 border-t border-border/60 pt-5 sm:pt-5") do
          expenditure_budget_form(record, suffix: suffix)
        end
      end
    end
  end

  def expenditure_slide_hint(record)
    if record
      "NT$#{format_decimal(record.amount)} · #{record.category} · 此筆已存入資料庫；表單僅供預覽／之後接上更新。"
    else
      "此區顯示本月支出預算列表。尚無資料時可新增第一筆（之後接上儲存）。"
    end
  end

  def expenditure_slide_header(index:, total:, record:)
    div(class: "border-b px-3 pb-3 pt-3 sm:px-4 sm:pb-3 sm:pt-4") do
      if total > 1
        p(class: "mb-2 text-[11px] font-medium tabular-nums text-muted-foreground sm:text-xs") do
          plain "第 #{index} 筆／共 #{total} 筆"
        end
      end
      div(class: "flex flex-row items-start justify-between gap-3") do
        div(class: "min-w-0 flex-1 pr-12 sm:pr-14") do
          if record
            label = record.category.presence || record.item
            p(class: "text-sm font-semibold leading-snug text-foreground") { label }
          end
          span(class: budget_month_label_class(record)) do
            current_month_label
          end
        end
        time(
          class: "shrink-0 text-xs tabular-nums text-muted-foreground sm:text-[13px]",
          data: { controller: "local-clock" }
        )
      end
    end
  end

  def revenue_budget_form(record, suffix:)
    form(class: "mx-auto max-w-xl space-y-6 sm:space-y-5", method: "post", action: "#") do
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      if record
        input(type: "hidden", name: "revenue_budget[id]", value: record.id)
      end
      input(type: "hidden", name: "revenue_budget[item]", value: record&.item.presence || "收入預算")

      budget_field_row(label: "金額：", id: "revenue_budget_amount_#{suffix}") do
        budget_twd_amount_input(
          id: "revenue_budget_amount_#{suffix}",
          name: "revenue_budget[amount]",
          value: (record ? format_decimal(record.amount) : ""),
          placeholder: "0",
          required: true
        )
      end

      budget_field_row(label: "備註：", id: "revenue_budget_note_#{suffix}") do
        Textarea(
          id: "revenue_budget_note_#{suffix}",
          name: "revenue_budget[note]",
          rows: 3,
          placeholder: "選填"
        ) { record&.note.to_s }
      end

      budget_form_actions
    end
  end

  def expenditure_budget_form(record, suffix:)
    form(class: "mx-auto max-w-xl space-y-6 sm:space-y-5", method: "post", action: "#") do
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      if record
        input(type: "hidden", name: "expenditure_budget[id]", value: record.id)
      end
      input(type: "hidden", name: "expenditure_budget[item]", value: record&.item.to_s)

      budget_field_row(label: "類別：", id: "expenditure_budget_category_#{suffix}") do
        div(
          class: [
            "w-full min-w-0 [&>div]:w-full",
            "[&_select]:min-h-11 [&_select]:py-2 sm:[&_select]:min-h-9 sm:[&_select]:py-1"
          ].join(" ")
        ) do
          expenditure_category_select(record, suffix: suffix)
        end
      end

      budget_field_row(label: "金額：", id: "expenditure_budget_amount_#{suffix}") do
        budget_twd_amount_input(
          id: "expenditure_budget_amount_#{suffix}",
          name: "expenditure_budget[amount]",
          value: (record ? format_decimal(record.amount) : ""),
          placeholder: "0",
          required: true
        )
      end

      budget_field_row(label: "備註：", id: "expenditure_budget_note_#{suffix}") do
        Textarea(
          id: "expenditure_budget_note_#{suffix}",
          name: "expenditure_budget[note]",
          rows: 3,
          placeholder: "選填"
        ) { record&.note.to_s }
      end

      budget_form_actions
    end
  end

  def expenditure_category_select(record, suffix:)
    has_cat = record&.category.present?
    NativeSelect(
      id: "expenditure_budget_category_#{suffix}",
      name: "expenditure_budget[category]",
      required: true
    ) do
      unless has_cat
        NativeSelectOption(value: "", disabled: true, selected: true) { plain "請選擇" }
      end
      ExpenditureTaxonomy::CATEGORIES.each do |cat|
        NativeSelectOption(value: cat, selected: has_cat && record.category == cat) { plain cat }
      end
    end
  end

  def budget_form_actions
    div(
      class: [
        "flex flex-col gap-3 pt-2 sm:flex-row sm:gap-2 sm:pt-1",
        "[&>button]:min-h-11 [&>button]:w-full sm:[&>button]:min-h-9 sm:[&>button]:w-auto"
      ].join(" ")
    ) do
      Button(type: :submit, variant: :primary, size: :md) { "儲存" }
      Button(type: :reset, variant: :outline, size: :md) { "清除" }
    end
  end

  def budget_field_row(label:, id:, &)
    div(class: "flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-4") do
      label(
        class: "shrink-0 text-sm font-medium leading-snug sm:w-40 sm:pt-2 sm:text-right",
        for: id
      ) { label }
      div(class: "min-w-0 flex-1") do
        yield
      end
    end
  end

  def budget_twd_amount_input(**input_attrs)
    div(class: "flex min-w-0 items-center gap-2") do
      span(class: "shrink-0 text-sm text-muted-foreground tabular-nums select-none") { "NT$" }
      div(class: "min-w-0 flex-1 max-sm:[&_input]:min-h-11") do
        Input(
          **input_attrs,
          type: :text,
          inputmode: "decimal"
        )
      end
    end
  end

  def budget_month_label_class(record)
    [
      "block text-xs tabular-nums text-muted-foreground sm:text-[13px]",
      ("mt-1" if record)
    ].compact.join(" ")
  end

  def current_month_label
    if @calendar_month
      "#{@calendar_month.year} 年 #{@calendar_month.month} 月"
    else
      t = Time.zone.today
      "#{t.year} 年 #{t.month} 月"
    end
  end

  def format_decimal(amount)
    format("%.2f", amount.to_d)
  end
end
