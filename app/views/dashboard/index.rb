# frozen_string_literal: true

class Views::Dashboard::Index < Views::Base
  def view_template
    div(class: PAGE_SHELL) do
      div(class: PAGE_TOP_STICKY) do
        header_row
        month_data_panel
      end
      div(class: PAGE_BODY_BELOW_STICKY) do
        form_panel
      end
    end
  end

  private

  def header_row
    div(class: "flex flex-row items-start justify-between gap-4 shrink-0") do
      div(class: "min-w-0 flex-1 space-y-2 pr-2") do
        h1(class: "text-balance text-2xl font-semibold tracking-tight sm:text-3xl") { "實際支出" }
        p(class: "max-w-prose text-sm leading-relaxed text-muted-foreground") { "登錄與檢視支出" }
      end
      div(class: "flex shrink-0 pt-0.5") do
        Link(href: expense_history_path, variant: :outline, size: :md) { "歷史紀錄" }
      end
    end
  end

  def month_data_panel
    section(
      class: [
        "flex shrink-0 flex-col rounded-xl border bg-card text-card-foreground shadow-sm ring-1 ring-border/40",
        "min-h-[12rem]"
      ],
      aria: { label: "本月支出資料" }
    ) do
      div(class: "border-b px-4 py-3") do
        div(class: "flex flex-col gap-0.5 sm:flex-row sm:items-baseline sm:justify-between") do
          h2(class: "text-sm font-medium") { "本月資料" }
          span(class: "text-xs text-muted-foreground tabular-nums") { current_month_label }
        end
      end
      div(class: "flex flex-col gap-5 p-5 sm:gap-6 sm:p-6") do
        p(class: "rounded-lg border border-border/50 bg-muted/25 px-3 py-2 text-sm leading-relaxed text-muted-foreground") do
          "此區顯示本月支出合計、分類摘要與列表（之後接上資料庫）。"
        end
      end
    end
  end

  def form_panel
    section(
      class: "rounded-xl border bg-card text-card-foreground shadow-sm ring-1 ring-border/40 shrink-0",
      aria: { label: "支出登錄表單" }
    ) do
      div(class: "border-b px-4 py-3") do
        h2(class: "text-sm font-medium") { "登錄支出" }
      end
      div(class: "flex flex-col gap-6 p-5 sm:p-6") do
        expenditure_entry_context_row
        form(
          class: "mx-auto w-full max-w-xl space-y-6",
          method: "post",
          action: "#",
          data: {
            controller: "expenditure-form",
            action: "reset->expenditure-form#formReset"
          }
        ) do
          input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)

          expenditure_field_row(label: "日期：", id: "actual_expenditure_transaction_date") do
            Input(
              id: "actual_expenditure_transaction_date",
              name: "actual_expenditure[transaction_date]",
              type: :date,
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
                placeholder: "輸入項目名稱...",
                required: true
              )
            end
          end

          expenditure_select_row(
            label: "消費類別：",
            id: "actual_expenditure_category",
            name: "actual_expenditure[category]",
            options: ExpenditureTaxonomy::CATEGORIES,
            required: true,
            prompt: "請選擇"
          )

          expenditure_select_row(
            label: "支付方式：",
            id: "actual_expenditure_payment_method",
            name: "actual_expenditure[payment_method]",
            options: ExpenditureTaxonomy::PAYMENT_METHODS,
            required: true,
            prompt: "請選擇",
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
              include_blank: true,
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
              options: ExpenditureTaxonomy::PAYMENT_PLATFORMS,
              include_blank: true,
              native_select: {
                data: { expenditure_form_target: "paymentPlatform" }
              }
            )
          end

          expenditure_field_row(label: "實際消費金額（TWD）：", id: "actual_expenditure_actual_amount") do
            twd_amount_input(
              id: "actual_expenditure_actual_amount",
              name: "actual_expenditure[actual_amount]",
              placeholder: "0",
              required: true
            )
          end

          expenditure_field_row(label: "列帳消費金額（TWD）：", id: "actual_expenditure_posted_amount") do
            twd_amount_input(
              id: "actual_expenditure_posted_amount",
              name: "actual_expenditure[posted_amount]",
              placeholder: "0",
              required: true
            )
          end

          expenditure_field_row(label: "備註：", id: "actual_expenditure_note") do
            Textarea(
              id: "actual_expenditure_note",
              name: "actual_expenditure[note]",
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
    div(class: "flex flex-row items-start justify-between gap-3 border-b border-border/60 pb-5") do
      div(class: "min-w-0 flex-1 pr-8 sm:pr-12") do
        span(class: "block text-xs tabular-nums text-muted-foreground sm:text-[13px]") do
          current_month_label
        end
      end
      time(
        class: "shrink-0 text-xs tabular-nums text-muted-foreground sm:text-[13px]",
        data: { controller: "local-clock" }
      )
    end
  end

  def expenditure_select_row(label:, id:, name:, options:, required: false, prompt: nil, include_blank: false, native_select: {})
    expenditure_field_row(label: label, id: id) do
      div(class: "w-full min-w-0 [&>div]:w-full") do
        NativeSelect(id: id, name: name, required: required, **native_select) do
          if prompt
            NativeSelectOption(value: "", disabled: true, selected: true) { plain prompt }
          elsif include_blank
            NativeSelectOption(value: "") { plain "（不適用／選填）" }
          end
          options.each do |value|
            NativeSelectOption(value: value) { plain value }
          end
        end
      end
    end
  end

  def twd_amount_input(**input_attrs)
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

  def expenditure_field_row(label:, id:, &)
    div(class: "flex flex-col gap-3.5 sm:flex-row sm:items-center sm:gap-5") do
      label(
        class: "shrink-0 text-sm font-medium leading-none sm:w-56 sm:flex-none sm:pt-2 sm:text-right",
        for: id
      ) { label }
      div(class: "min-w-0 flex-1") do
        yield
      end
    end
  end

  def current_month_label
    t = Time.zone.today
    "#{t.year} 年 #{t.month} 月"
  end
end
