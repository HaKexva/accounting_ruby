# frozen_string_literal: true

class Views::Budgets::Index < Views::Base
  def initialize(
    revenue_budgets:,
    expenditure_budgets:,
    calendar_month:,
    taxonomy:,
    initial_budget_kind: :revenue,
    revenue_carousel_initial_index: nil,
    expenditure_carousel_initial_index: nil
  )
    @revenue_budgets = revenue_budgets
    @expenditure_budgets = expenditure_budgets
    @calendar_month = calendar_month
    @taxonomy = taxonomy
    @initial_budget_kind = initial_budget_kind
    @revenue_carousel_initial_index = revenue_carousel_initial_index
    @expenditure_carousel_initial_index = expenditure_carousel_initial_index
  end

  def view_template
    div(class: PAGE_SHELL, data: { controller: "budget-allocation-chart" }) do
      div(
        class: "flex min-h-0 w-full flex-1 flex-col",
        data: { controller: "budget-live-totals" }
      ) do
        div(class: "hidden shrink-0 border-b border-border/50 pb-3 lg:block lg:pb-4") do
          budget_header_row
        end

        div(class: PAGE_SPLIT_GRID_CLASS) do
          div(class: PAGE_SPLIT_LEFT_STICKY_CLASS) do
            div(class: "shrink-0 lg:hidden") { budget_header_row }
            div(class: "min-h-0 flex-1 overflow-y-auto overscroll-contain lg:overflow-visible lg:flex-none") do
              budget_month_summary_panel
            end
          end

          div(class: PAGE_SPLIT_RIGHT_BODY_CLASS) do
            budget_main_editor_section_intro

            div(class: "w-full space-y-4", data: { controller: "budgets-kind" }) do
              budget_kind_switcher

              div(
                class: (@initial_budget_kind == :expenditure) ? "hidden" : nil,
                data: { budgets_kind_target: "revenuePanel" }
              ) do
                revenue_budget_deck
              end

              div(
                class: (@initial_budget_kind == :revenue) ? "hidden" : nil,
                data: { budgets_kind_target: "expenditurePanel" }
              ) do
                expenditure_budget_deck
              end
            end

            budget_footer_hint
          end
        end
      end
    end
  end

  private

  def revenue_budget_member_prefix
    "#{budget_revenue_budget_path(1).sub(%r{/1\z}, "")}/"
  end

  def expenditure_budget_member_prefix
    "#{budget_expenditure_budget_path(1).sub(%r{/1\z}, "")}/"
  end

  # One trailing blank card only (new entry). Landing opens that last slide; saved rows come first.
  def budget_slides_with_trailing_new(records)
    records.dup + [ nil ]
  end

  def revenue_budget_deck
    slides = budget_slides_with_trailing_new(@revenue_budgets)
    budget_deck_wrapper do
      Carousel(
        tabindex: "0",
        initial_index: @revenue_carousel_initial_index,
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
          saved_total = @revenue_budgets.size
          slides.each_with_index do |record, idx|
            saved_index = record ? idx + 1 : nil
            CarouselItem do
              revenue_budget_slide(record, saved_index: saved_index, saved_count: saved_total)
            end
          end
        end
        CarouselNext
      end
    end
  end

  def expenditure_budget_deck
    slides = budget_slides_with_trailing_new(@expenditure_budgets)
    budget_deck_wrapper do
      Carousel(
        tabindex: "0",
        initial_index: @expenditure_carousel_initial_index,
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
          saved_total = @expenditure_budgets.size
          slides.each_with_index do |record, idx|
            saved_index = record ? idx + 1 : nil
            CarouselItem do
              expenditure_budget_slide(record, saved_index: saved_index, saved_count: saved_total)
            end
          end
        end
        CarouselNext
      end
    end
  end

  def budget_deck_wrapper(&)
    div(class: "relative w-full") do
      div(
        class: [
          "overflow-hidden rounded-xl border bg-card text-card-foreground",
          "shadow-md ring-1 ring-border/50 ring-offset-1 ring-offset-background"
        ].join(" ")
      ) do
        yield
      end
    end
  end

  def budget_main_editor_section_intro
    div(class: "space-y-0.5 scroll-mt-6 sm:scroll-mt-8") do
      h2(class: "text-lg font-semibold tracking-tight text-foreground sm:text-xl") { "填寫預算" }
      p(class: "max-w-prose text-sm leading-snug text-muted-foreground") do
        plain "此處為主要操作區：編輯欄位後會自動儲存，卡片右上角可刪除該筆。"
      end
    end
  end

  def budget_kind_switcher
    div(class: "flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-4") do
      span(class: "text-base font-semibold tracking-tight text-foreground sm:text-lg") { "新增" }
      div(class: "min-w-0 flex-1 sm:max-w-md") do
        div(class: "#{SEGMENTED_CONTROL_CLASS} w-full", role: "group", aria: { label: "預算類型" }) do
          budget_kind_segment_button(:revenue, "收入預算")
          budget_kind_segment_button(:expenditure, "支出預算")
        end
        NativeSelect(
          id: "budget_kind_select",
          class: "sr-only",
          aria: { label: "預算類型" },
          data: {
            budgets_kind_target: "kindSelect",
            action: "change->budgets-kind#sync"
          }
        ) do
          NativeSelectOption(value: "revenue", selected: @initial_budget_kind == :revenue) { plain "收入預算" }
          NativeSelectOption(value: "expenditure", selected: @initial_budget_kind == :expenditure) { plain "支出預算" }
        end
      end
    end
  end

  def budget_kind_segment_button(kind, label)
    active = @initial_budget_kind == kind
    button(
      type: "button",
      class: [
        SEGMENTED_CONTROL_BTN_CLASS,
        (active ? SEGMENTED_CONTROL_BTN_ACTIVE_CLASS : nil)
      ].compact.join(" "),
      data: {
        kind_value: kind.to_s,
        budgets_kind_target: "kindButton",
        action: "click->budgets-kind#pickKind"
      },
      aria: { pressed: active }
    ) { label }
  end

  def budget_header_row
    page_header(
      title: "預算",
      subtitle: "規劃本月收入與各類別支出預算"
    )
  end

  def budget_month_summary_panel
    section(class: MONTH_SUMMARY_SECTION_CLASS, aria: { label: "本月預算摘要" }) do
      div(class: MONTH_SUMMARY_HEADER_CLASS) do
        div(class: "flex flex-col gap-0.5 sm:flex-row sm:items-baseline sm:justify-between") do
          h2(class: MONTH_SUMMARY_TITLE_CLASS) { "本月摘要" }
          span(class: MONTH_SUMMARY_PERIOD_CLASS) { current_month_label }
        end
      end
      div(class: MONTH_SUMMARY_BODY_CLASS) do
        div(class: MONTH_SUMMARY_STATS_ROW_CLASS) do
          budget_summary_stat(label: "收入預算合計", total: revenue_budget_total, count: @revenue_budgets.size, kind: :revenue)
          budget_summary_stat(label: "支出預算合計", total: expenditure_budget_total, count: @expenditure_budgets.size, kind: :expenditure)
          budget_summary_net_stat(total: revenue_budget_total - expenditure_budget_total)
        end
        div(class: CHART_PANEL_CLASS) do
          p(class: "shrink-0 text-center text-xs font-medium text-foreground") { "收入運用" }
          p(class: "shrink-0 text-center text-[11px] leading-snug text-muted-foreground sm:text-xs") { "各類支出與未使用收入（即時連動；有填收入時占比以收入合計為分母）" }
          div(class: "flex w-full shrink justify-center py-1") do
            div(class: CHART_CANVAS_WRAP_CLASS) do
              canvas(
                class: "block h-full w-full max-h-full",
                role: "img",
                aria: { label: "圓餅圖：收入合計中各類支出與未使用收入占比" },
                data: { budget_allocation_chart_target: "canvas" }
              )
            end
          end
          div(
            class: "min-h-0 w-full shrink-0 px-1 sm:px-2",
            data: { budget_allocation_chart_target: "chartLegend" },
            aria: { label: "支出類別與未使用收入圖例" }
          )
        end
      end
    end
  end

  def budget_footer_hint
    p(
      class: [
        "mt-4 w-full rounded-xl border border-border/60 bg-muted/30 px-4 py-2.5 text-center text-[11px]",
        "leading-relaxed text-muted-foreground sm:mt-5 sm:py-3 sm:text-xs"
      ].join(" ")
    ) do
      plain "未登入時以試用身分寫入。於「填寫預算」區編輯會自動儲存，卡片右上角可刪除該筆。"
    end
  end

  def revenue_budget_slide(record, saved_index:, saved_count:)
    suffix = record ? "rev_#{record.id}" : "rev_new"
    title = record&.item.presence || "新增收入預算"
    aria = if saved_index
      "#{title}（第 #{saved_index} 筆／共 #{saved_count} 筆）"
    else
      suffix_aria = saved_count.positive? ? "已登錄 #{saved_count} 筆" : "尚無已登錄資料"
      "#{title}。未儲存的新增列，不計入筆數；#{suffix_aria}。"
    end
    action = record ? budget_revenue_budget_path(record.id) : budget_revenue_budgets_path
    form_id = "revenue_budget_form_#{suffix}"

    auto_save_data = {
      controller: "budget-auto-save",
      action: "input->budget-auto-save#scheduleSave change->budget-auto-save#scheduleSave",
      budget_auto_save_member_prefix_value: revenue_budget_member_prefix
    }
    auto_save_data[:budget_auto_save_record_id_value] = record.id if record

    section(
      class: [
        "flex min-h-[min(22rem,58svh)] flex-col bg-transparent",
        "sm:min-h-[min(26rem,70svh)]",
        "md:min-h-[min(30rem,76svh)]"
      ].join(" "),
      aria: { label: aria }
    ) do
      div(class: "flex flex-1 flex-col gap-5 p-4 sm:gap-6 sm:p-6") do
        div(
          class: "mx-auto flex w-full max-w-[17.5rem] flex-col space-y-6 sm:max-w-md lg:max-w-xl",
          data: auto_save_data
        ) do
          revenue_slide_header(
            saved_index: saved_index,
            saved_count: saved_count,
            delete_path: record ? delete_budget_revenue_budget_path(record) : nil,
            unsaved_delete: record.nil?
          )

          form(
            id: form_id,
            class: "flex flex-col space-y-1",
            action: action,
            method: "post",
            data: { budget_auto_save_target: "budgetForm" }
          ) do
            input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
            if record
              input(type: "hidden", name: "_method", value: "patch")
            end

            p(
              class: "hidden text-[11px] tabular-nums text-muted-foreground",
              data: { budget_auto_save_target: "status" }
            ) { plain "" }

            div(class: "flex-1 space-y-5 sm:space-y-6") do
              budget_field_row(label: "項目：", id: "revenue_budget_item_#{suffix}") do
                budget_single_line_text_input(
                  id: "revenue_budget_item_#{suffix}",
                  name: "revenue_budget[item]",
                  value: record&.item.presence || "",
                  placeholder: "輸入項目名稱...",
                  required: true
                )
              end

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
            end
          end
        end
      end
    end
  end

  def revenue_slide_header(saved_index:, saved_count:, delete_path: nil, unsaved_delete: false)
    div(class: "px-0 pb-2 pt-0 sm:pb-3") do
      div(class: "flex flex-row items-start justify-between gap-2") do
        p(class: "mb-0 min-w-0 flex-1 text-[11px] font-medium tabular-nums text-muted-foreground sm:text-xs") do
          if saved_index
            plain "第 #{saved_index} 筆／共 #{saved_count} 筆"
          elsif saved_count.positive?
            plain "新增預算 · 已登錄 #{saved_count} 筆（空白卡不計入）"
          else
            plain "新增預算 · 尚無已登錄資料"
          end
        end

        if unsaved_delete || delete_path
          div(class: "shrink-0", data: { budget_auto_save_target: "deleteSlot" }) do
            if unsaved_delete
              Button(
                type: :button,
                variant: :destructive,
                size: :md,
                class: "shrink-0 shadow-sm",
                data: {
                  budget_auto_save_target: "discardButton",
                  action: "click->budget-auto-save#discardUnsaved"
                }
              ) { "刪除" }
            elsif delete_path
              form(method: "post", action: delete_path, class: "inline-flex shrink-0 items-center") do
                input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
                input(type: "hidden", name: "_method", value: "delete")
                Button(
                  type: :submit,
                  variant: :destructive,
                  size: :md,
                  class: "shadow-sm",
                  data: { turbo_confirm: "確定刪除此筆預算？" }
                ) { "刪除" }
              end
            end
          end
        end
      end

      div(class: "mt-2 flex flex-row items-start justify-between gap-3") do
        span(class: [ budget_month_label_class, "min-w-0 flex-1 pr-2" ].join(" ")) do
          current_month_label
        end
        time(
          class: "shrink-0 text-xs tabular-nums text-muted-foreground sm:text-[13px]",
          data: { controller: "local-clock" }
        )
      end
    end
  end

  def expenditure_budget_slide(record, saved_index:, saved_count:)
    suffix = record ? "exp_#{record.id}" : "exp_new"
    title = record&.category.presence || record&.item.presence || "新增支出預算"
    aria = if saved_index
      "#{title}（第 #{saved_index} 筆／共 #{saved_count} 筆）"
    else
      suffix_aria = saved_count.positive? ? "已登錄 #{saved_count} 筆" : "尚無已登錄資料"
      "#{title}。未儲存的新增列，不計入筆數；#{suffix_aria}。"
    end
    action = record ? budget_expenditure_budget_path(record.id) : budget_expenditure_budgets_path
    form_id = "expenditure_budget_form_#{suffix}"

    auto_save_data = {
      controller: "budget-auto-save",
      action: "input->budget-auto-save#scheduleSave change->budget-auto-save#scheduleSave",
      budget_auto_save_member_prefix_value: expenditure_budget_member_prefix
    }
    auto_save_data[:budget_auto_save_record_id_value] = record.id if record

    section(
      class: [
        "flex min-h-[min(22rem,58svh)] flex-col bg-transparent",
        "sm:min-h-[min(26rem,70svh)]",
        "md:min-h-[min(30rem,76svh)]"
      ].join(" "),
      aria: { label: aria }
    ) do
      div(class: "flex flex-1 flex-col gap-5 p-4 sm:gap-6 sm:p-6") do
        div(
          class: "mx-auto flex w-full max-w-[17.5rem] flex-col space-y-6 sm:max-w-md lg:max-w-xl",
          data: auto_save_data
        ) do
          expenditure_slide_header(
            saved_index: saved_index,
            saved_count: saved_count,
            delete_path: record ? delete_budget_expenditure_budget_path(record) : nil,
            unsaved_delete: record.nil?
          )

          form(
            id: form_id,
            class: "flex flex-col space-y-1",
            action: action,
            method: "post",
            data: { budget_auto_save_target: "budgetForm" }
          ) do
            input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
            if record
              input(type: "hidden", name: "_method", value: "patch")
            end

            p(
              class: "hidden text-[11px] tabular-nums text-muted-foreground",
              data: { budget_auto_save_target: "status" }
            ) { plain "" }

            div(class: "flex-1 space-y-5 sm:space-y-6") do
              budget_field_row(label: "項目：", id: "expenditure_budget_item_#{suffix}") do
                budget_single_line_text_input(
                  id: "expenditure_budget_item_#{suffix}",
                  name: "expenditure_budget[item]",
                  value: record&.item.to_s,
                  placeholder: "輸入項目名稱...",
                  required: true
                )
              end

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
            end
          end
        end
      end
    end
  end

  def expenditure_slide_header(saved_index:, saved_count:, delete_path: nil, unsaved_delete: false)
    div(class: "px-0 pb-2 pt-0 sm:pb-3") do
      div(class: "flex flex-row items-start justify-between gap-2") do
        p(class: "mb-0 min-w-0 flex-1 text-[11px] font-medium tabular-nums text-muted-foreground sm:text-xs") do
          if saved_index
            plain "第 #{saved_index} 筆／共 #{saved_count} 筆"
          elsif saved_count.positive?
            plain "新增預算 · 已登錄 #{saved_count} 筆（空白卡不計入）"
          else
            plain "新增預算 · 尚無已登錄資料"
          end
        end

        if unsaved_delete || delete_path
          div(class: "shrink-0", data: { budget_auto_save_target: "deleteSlot" }) do
            if unsaved_delete
              Button(
                type: :button,
                variant: :destructive,
                size: :md,
                class: "shrink-0 shadow-sm",
                data: {
                  budget_auto_save_target: "discardButton",
                  action: "click->budget-auto-save#discardUnsaved"
                }
              ) { "刪除" }
            elsif delete_path
              form(method: "post", action: delete_path, class: "inline-flex shrink-0 items-center") do
                input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
                input(type: "hidden", name: "_method", value: "delete")
                Button(
                  type: :submit,
                  variant: :destructive,
                  size: :md,
                  class: "shadow-sm",
                  data: { turbo_confirm: "確定刪除此筆預算？" }
                ) { "刪除" }
              end
            end
          end
        end
      end

      div(class: "mt-2 flex flex-row items-start justify-between gap-3") do
        span(class: [ budget_month_label_class, "min-w-0 flex-1 pr-2" ].join(" ")) do
          current_month_label
        end
        time(
          class: "shrink-0 text-xs tabular-nums text-muted-foreground sm:text-[13px]",
          data: { controller: "local-clock" }
        )
      end
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
      @taxonomy.categories.each do |cat|
        NativeSelectOption(value: cat, selected: has_cat && record.category == cat) { plain cat }
      end
    end
  end

  def budget_field_row(label:, id:, &)
    div(class: "flex flex-col gap-3.5 sm:flex-row sm:items-center sm:gap-5") do
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

  def budget_single_line_text_input(id:, name:, value:, placeholder:, required:)
    div(class: "min-w-0 flex-1 max-sm:[&_input]:min-h-11") do
      Input(
        id: id,
        name: name,
        type: :text,
        value: value,
        placeholder: placeholder,
        required: required
      )
    end
  end

  def budget_month_label_class
    "block text-xs tabular-nums text-muted-foreground sm:text-[13px]"
  end

  def current_month_label
    calendar_month_label_for(@calendar_month)
  end

  def format_decimal(amount)
    Kernel.format("%.0f", amount.to_d.round)
  end

  def revenue_budget_total
    @revenue_budgets.sum(&:amount).to_d
  end

  def expenditure_budget_total
    @expenditure_budgets.sum(&:amount).to_d
  end

  def budget_summary_stat(label:, total:, count:, kind:)
    total_target = kind == :revenue ? "revenueTotal" : "expenditureTotal"
    count_target = kind == :revenue ? "revenueCount" : "expenditureCount"
    accent = kind == :revenue ? :remain : :expense
    div(
      class: "#{stat_chip_class(accent: accent)} basis-[calc(33.333%-0.35rem)] sm:basis-auto",
      title: label
    ) do
      p(class: STAT_CHIP_LABEL_CLASS) { label }
      p(class: STAT_CHIP_VALUE_CLASS, data: { budget_live_totals_target: total_target }) { "NT$#{format_decimal(total)}" }
      p(class: STAT_CHIP_META_CLASS, data: { budget_live_totals_target: count_target }) { "#{count} 筆" }
    end
  end

  def budget_summary_net_stat(total:)
    div(
      class: "#{stat_chip_class(accent: :budget)} basis-[calc(33.333%-0.35rem)] sm:basis-auto",
      title: "相減（收入−支出）"
    ) do
      p(class: STAT_CHIP_LABEL_CLASS) { "淨額" }
      p(class: STAT_CHIP_VALUE_CLASS, data: { budget_live_totals_target: "netTotal" }) { "NT$#{format_decimal(total)}" }
    end
  end
end
