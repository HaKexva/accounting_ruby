# frozen_string_literal: true

class Views::Dashboard::Index < Views::Base
  include Views::Dashboard::ActualExpenditureFormFields

  ACTUAL_EXPENDITURE_FORM_ID = "dashboard_actual_expenditure_form"

  def initialize(
    calendar_month:,
    month_choices:,
    month_total:,
    month_count:,
    category_amounts:,
    category_budgets:,
    expenditure_budget_total:,
    revenue_total:,
    taxonomy:
  )
    @calendar_month = calendar_month
    @month_choices = month_choices
    @month_total = month_total
    @month_count = month_count
    @category_amounts = category_amounts
    @category_budgets = category_budgets
    @expenditure_budget_total = expenditure_budget_total
    @revenue_total = revenue_total
    @taxonomy = taxonomy
  end

  def view_template
    div(
      class: PAGE_SHELL,
      data: {
        controller: [
          "expenditure-month-chart",
          "actual-expenditure-form",
          "expenditure-form",
          "expenditure-mobile-sticky-summary",
          "expenditure-live-category-summary"
        ].join(" "),
        expenditure_month_chart_categories_value: chart_categories_json,
        expenditure_month_chart_budgets_value: category_budgets_json,
        expenditure_month_chart_revenue_total_value: @revenue_total.to_f,
        expenditure_month_chart_category_order_value: @taxonomy.categories.to_json,
        expenditure_live_category_summary_budgets_value: category_budgets_json,
        expenditure_live_category_summary_spent_value: chart_categories_json,
        action: [
          "actual-expenditure-form:success->expenditure-month-chart#applyTally",
          "actual-expenditure-form:success->expenditure-live-category-summary#applySpent",
          "reset->expenditure-live-category-summary#recalc"
        ].join(" ")
      }
    ) do
      div(class: "hidden lg:block #{PAGE_TOP_STICKY} border-border/50") do
        header_row
      end

      div(class: PAGE_SPLIT_GRID_CLASS) do
        div(class: PAGE_SPLIT_LEFT_STICKY_CLASS) do
          div(class: "shrink-0 lg:hidden") { header_row }
          div(class: "min-h-0 flex-1 overflow-y-auto overscroll-contain lg:overflow-visible lg:flex-none") do
            div(
              class: "relative min-h-0 lg:contents",
              data: { expenditure_mobile_sticky_summary_target: "stickyPanel" }
            ) do
              month_data_panel
            end
          end
        end

        div(class: PAGE_SPLIT_RIGHT_BODY_CLASS) do
          form_section_intro
          form_panel
        end
      end
    end
  end

  private

  def chart_categories_json
    h = @category_amounts.transform_values { |v| v.to_f }
    h.to_json
  end

  def category_budgets_json
    h = @category_budgets.transform_values { |v| v.to_f }
    h.to_json
  end

  def form_section_intro
    div(class: "space-y-0.5 scroll-mt-6 sm:scroll-mt-8 lg:hidden") do
      h2(class: "text-lg font-semibold tracking-tight text-foreground sm:text-xl") { "登錄支出" }
    end
  end

  def header_row
    page_header(title: "實際支出", subtitle: "登錄本月支出並即時查看預算餘額") do
      Link(href: expense_history_path(**history_ym_params), variant: :outline, size: :md) { "歷史紀錄" }
    end
  end

  def month_data_panel
    section(class: "#{MONTH_SUMMARY_SECTION_CLASS}", aria: { label: "本月實際支出摘要" }) do
      div(
        class: MONTH_SUMMARY_HEADER_CLASS,
        data: { expenditure_mobile_sticky_summary_target: "summaryHeader" }
      ) do
        div(class: "flex flex-col gap-1") do
          div(class: "flex items-baseline justify-between gap-2") do
            h2(class: MONTH_SUMMARY_TITLE_CLASS) { "月份摘要" }
            div(class: "flex shrink-0 items-center gap-1.5 whitespace-nowrap text-right") do
              calendar_month_selector(
                month_choices: @month_choices,
                calendar_month: @calendar_month,
                url: root_path,
                select_id: "dashboard_calendar_month"
              )
              span(class: MONTH_SUMMARY_PERIOD_CLASS) { plain "·" }
              span(
                class: "tabular-nums #{MONTH_SUMMARY_PERIOD_CLASS}",
                data: { actual_expenditure_form_target: "monthCount" }
              ) { plain "#{@month_count} 筆" }
            end
          end
          p(
            class: "text-[11px] leading-snug text-muted-foreground sm:text-xs",
            data: { expenditure_mobile_sticky_summary_target: "summaryHint" }
          ) do
            plain "依目前選擇的消費類別（預算來自本月支出預算）"
          end
        end
      end
      div(class: MONTH_SUMMARY_BODY_CLASS) do
        desktop_summary_squares
        mobile_category_stat_squares
        div(class: CHART_PANEL_CLASS, data: { expenditure_mobile_sticky_summary_target: "chartPanel" }) do
          p(class: "shrink-0 text-center text-xs font-medium text-foreground") { "本月消費支出結構" }
          p(class: "shrink-0 text-center text-[11px] leading-snug text-muted-foreground sm:text-xs") do
            plain "各類別同色：淺色＝尚未使用預算、深色＝已使用；另含預算收入－預算支出（占比以收入預算合計為分母）"
          end
          div(class: "flex w-full shrink justify-center py-1") do
            div(class: CHART_CANVAS_WRAP_CLASS) do
              canvas(
                class: "block h-full w-full max-h-full",
                role: "img",
                aria: { label: "圓餅圖：本月消費支出結構" },
                data: { expenditure_month_chart_target: "canvas" }
              )
            end
          end
          div(
            class: "min-h-0 w-full shrink-0 px-1 sm:px-2",
            data: { expenditure_month_chart_target: "chartLegend" },
            aria: { label: "類別圖例" }
          )
        end
      end
    end
  end

  def desktop_summary_squares
    div(class: DESKTOP_SUMMARY_GRID_CLASS) do
      div(class: desktop_summary_square_class(accent: :remain)) do
        p(class: "text-[11px] font-semibold text-foreground sm:text-xs") { "類別統計" }
        div(class: "mt-1 min-w-0 space-y-0.5") do
          desktop_category_stat_line(label: "預算", target: "budgetAmount")
          desktop_category_stat_line(label: "支出", target: "expenseAmount")
          desktop_category_stat_line(label: "餘額", target: "remainAmount", label_target: "remainLabel")
        end
      end

      div(class: desktop_summary_square_class(accent: :budget)) do
        p(class: "text-[11px] font-semibold text-foreground sm:text-xs") { "總預算" }
        p(class: "mt-1 min-w-0 truncate text-sm font-semibold tabular-nums text-foreground sm:text-base") do
          plain "NT$#{format_decimal(@expenditure_budget_total)}"
        end
        p(class: "mt-auto text-[10px] leading-snug text-muted-foreground") { "本月支出預算" }
      end

      div(class: desktop_summary_square_class(accent: :expense)) do
        p(class: "text-[11px] font-semibold text-foreground sm:text-xs") { "總支出" }
        p(
          id: "dashboard_month_total",
          class: "mt-1 min-w-0 truncate text-sm font-semibold tabular-nums text-foreground sm:text-base",
          data: { actual_expenditure_form_target: "monthTotal" }
        ) do
          plain "NT$#{format_decimal(@month_total)}"
        end
        p(class: "mt-auto text-[10px] leading-snug text-muted-foreground") { "本月實際支出" }
      end
    end
  end

  def desktop_category_stat_line(label:, target:, label_target: nil)
    p(class: "min-w-0 truncate text-[10px] text-muted-foreground sm:text-[11px]") do
      if label_target
        span(data: { expenditure_live_category_summary_target: label_target }) { label }
      else
        plain label
      end
      plain " "
      span(
        class: "font-semibold tabular-nums text-foreground",
        data: { expenditure_live_category_summary_target: target }
      ) { plain "NT$0" }
    end
  end

  def mobile_category_stat_squares
    div(
      class: "lg:hidden #{MOBILE_CATEGORY_STATS_ROW_CLASS}",
      data: { expenditure_mobile_sticky_summary_target: "statsRow" }
    ) do
      category_summary_chip(
        label: "預算",
        target: "budgetAmount",
        initial: "NT$0",
        accent: :budget
      )
      category_summary_chip(
        label: "支出",
        target: "expenseAmount",
        initial: "NT$0",
        accent: :expense
      )
      category_summary_chip(
        label: "餘額",
        target: "remainAmount",
        label_target: "remainLabel",
        initial: "NT$0",
        accent: :remain
      )
    end
  end

  def category_summary_chip(label:, target:, initial:, label_target: nil, accent: nil)
    div(
      class: mobile_stat_chip_class(accent: accent),
      data: { expenditure_mobile_sticky_summary_target: "chip" }
    ) do
      p(
        class: STAT_CHIP_LABEL_CLASS,
        data: {
          expenditure_mobile_sticky_summary_target: "chipLabel"
        }.merge(label_target ? { expenditure_live_category_summary_target: label_target } : {})
      ) { label }
      p(
        class: STAT_CHIP_VALUE_CLASS,
        data: {
          expenditure_live_category_summary_target: target,
          expenditure_mobile_sticky_summary_target: "chipValue"
        }
      ) { plain initial }
    end
  end

  def form_panel
    section(class: "#{CARD_SECTION_CLASS} lg:h-fit", aria: { label: "支出登錄表單" }) do
      div(class: "hidden border-b border-border/60 bg-muted/15 px-4 py-3.5 lg:block sm:px-5") do
        h2(class: MONTH_SUMMARY_TITLE_CLASS) { "登錄支出" }
        p(class: "mt-0.5 text-xs text-muted-foreground") { "填寫後即時更新左側摘要" }
      end
      div(class: "flex flex-col gap-6 p-5 sm:p-6") do
        expenditure_entry_context_row
        form(
          id: ACTUAL_EXPENDITURE_FORM_ID,
          class: "w-full max-w-full space-y-6",
          method: "post",
          action: actual_expenditures_path,
          data: {
            actual_expenditure_form_target: "mainForm",
            action: "reset->expenditure-form#formReset"
          }
        ) do
          input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
          input(type: "hidden", name: "ym", value: calendar_month_ym)

          p(
            class: "hidden rounded-md border border-border/60 bg-muted/40 px-2 py-1.5 text-[11px] text-foreground",
            data: { actual_expenditure_form_target: "status" }
          ) { plain "" }

          expenditure_field_row(label: "日期：", id: "actual_expenditure_transaction_date") do
            Input(
              id: "actual_expenditure_transaction_date",
              name: "actual_expenditure[transaction_date]",
              type: :date,
              form: ACTUAL_EXPENDITURE_FORM_ID,
              value: Time.zone.today.strftime("%Y-%m-%d"),
              required: true
            )
          end

          expenditure_field_row(label: "項目：", id: "actual_expenditure_transaction_item") do
            div(class: "min-w-0 flex-1 max-sm:[&_input]:min-h-11") do
              Input(
                id: "actual_expenditure_transaction_item",
                name: "actual_expenditure[transaction_item]",
                type: :text,
                form: ACTUAL_EXPENDITURE_FORM_ID,
                placeholder: "輸入項目名稱...",
                required: true
              )
            end
          end

          expenditure_select_row(
            label: "消費類別：",
            id: "actual_expenditure_category",
            name: "actual_expenditure[category]",
            options: @taxonomy.categories,
            required: true,
            prompt: "請選擇",
            form: ACTUAL_EXPENDITURE_FORM_ID,
            live_summary: true
          )

          expenditure_select_row(
            label: "支付方式：",
            id: "actual_expenditure_payment_method",
            name: "actual_expenditure[payment_method]",
            options: @taxonomy.payment_methods,
            required: true,
            prompt: "請選擇",
            form: ACTUAL_EXPENDITURE_FORM_ID,
            native_select: {
              data: {
                expenditure_form_target: "paymentMethod",
                action: "change->expenditure-form#paymentMethodChanged"
              }
            }
          )

          div(
            class: "hidden flex flex-col gap-6 sm:gap-6",
            data: { expenditure_form_target: "creditCardSection" }
          ) do
            expenditure_select_row(
              label: "信用卡支付方式：",
              id: "actual_expenditure_credit_card_payment_method",
              name: "actual_expenditure[credit_card_payment_method]",
              options: ExpenditureTaxonomy::CREDIT_CARD_PAYMENT_KINDS,
              required: false,
              prompt: "請選擇",
              include_blank: false,
              form: ACTUAL_EXPENDITURE_FORM_ID,
              native_select: {
                disabled: true,
                data: { expenditure_form_target: "creditCardPaymentMethod" }
              }
            )

            expenditure_select_row(
              label: "本月／次月支付：",
              id: "actual_expenditure_payment_timing",
              name: "actual_expenditure[payment_timing]",
              options: ExpenditureTaxonomy::PAYMENT_TIMINGS,
              required: false,
              prompt: "請選擇",
              include_blank: false,
              form: ACTUAL_EXPENDITURE_FORM_ID,
              native_select: {
                disabled: true,
                data: { expenditure_form_target: "paymentTiming" }
              }
            )
          end

          div(
            class: "hidden",
            data: { expenditure_form_target: "paymentPlatformSection" }
          ) do
            expenditure_select_row(
              label: "支付平台：",
              id: "actual_expenditure_payment_platform",
              name: "actual_expenditure[payment_platform]",
              options: @taxonomy.payment_platforms,
              prompt: "請選擇",
              form: ACTUAL_EXPENDITURE_FORM_ID,
              native_select: {
                disabled: true,
                data: { expenditure_form_target: "paymentPlatform" }
              }
            )
          end

          expenditure_field_row(label: "實際消費金額（TWD）：", id: "actual_expenditure_actual_amount") do
            twd_amount_input(
              live_summary: true,
              id: "actual_expenditure_actual_amount",
              name: "actual_expenditure[actual_amount]",
              form: ACTUAL_EXPENDITURE_FORM_ID,
              placeholder: "0",
              required: true,
              data: { expenditure_mobile_sticky_summary_target: "amountInput" }
            )
          end

          expenditure_field_row(label: "列帳消費金額（TWD）：", id: "actual_expenditure_posted_amount") do
            twd_amount_input(
              live_summary: true,
              id: "actual_expenditure_posted_amount",
              name: "actual_expenditure[posted_amount]",
              form: ACTUAL_EXPENDITURE_FORM_ID,
              placeholder: "0",
              required: true,
              data: { expenditure_mobile_sticky_summary_target: "amountInput" }
            )
          end

          expenditure_field_row(label: "備註：", id: "actual_expenditure_note") do
            Textarea(
              id: "actual_expenditure_note",
              name: "actual_expenditure[note]",
              form: ACTUAL_EXPENDITURE_FORM_ID,
              rows: 3,
              placeholder: "選填"
            )
          end

          div(class: "flex flex-col gap-3 pt-5 sm:flex-row sm:gap-3 sm:pt-6 [&>button]:min-h-11 sm:[&>button]:min-h-9") do
            Button(type: :submit, variant: :primary, size: :md) { "儲存" }
            Button(type: :reset, variant: :outline, size: :md) { "清除" }
          end
        end
      end
    end
  end

  def expenditure_entry_context_row
    div(class: "flex flex-row items-start justify-end gap-3 border-b border-border/60 pb-5") do
      time(
        class: "shrink-0 text-xs tabular-nums text-muted-foreground sm:text-[13px]",
        data: { controller: "local-clock" }
      )
    end
  end

  def calendar_month_ym
    calendar_month_ym_for(@calendar_month)
  end

  def history_ym_params
    calendar_month_ym.present? ? { ym: calendar_month_ym } : {}
  end
end
