# frozen_string_literal: true

class Views::Budgets::Index < Views::Base
  def view_template
    div(class: "flex min-h-0 w-full flex-col lg:mx-auto lg:max-w-3xl", data: { controller: "budgets-kind" }) do
      div(
        class: [
          "sticky top-0 z-10 shrink-0 space-y-6 bg-background pb-4",
          "border-b border-border/60"
        ]
      ) do
        budget_header_row
        budget_summary_section(
          target: "revenueSummary",
          hidden: false,
          aria_label: "本月收入預算資料",
          body_hint: "此區顯示本月收入預算合計、摘要與列表（之後接上資料庫）。"
        )
        budget_summary_section(
          target: "expenditureSummary",
          hidden: true,
          aria_label: "本月支出預算資料",
          body_hint: "此區顯示本月支出預算合計、摘要與列表（之後接上資料庫）。"
        )
      end

      budget_kind_row

      div(class: "shrink-0 pt-6") do
        revenue_budget_entry_section
        expenditure_budget_entry_section
      end
    end
  end

  private

  def budget_header_row
    div(class: "space-y-1 shrink-0") do
      h1(class: "text-2xl font-semibold tracking-tight") { "預算" }
      p(class: "mt-1 text-sm text-muted-foreground") { "檢視與登錄預算。" }
    end
  end

  def budget_kind_row
    div(class: "flex shrink-0 flex-col items-center gap-2 border-b border-border/60 bg-background py-4") do
      label(class: "text-sm font-medium text-muted-foreground", for: "budget_kind_select") { "預算類型" }
      div(class: "w-full max-w-xs [&>div]:w-full") do
        NativeSelect(
          id: "budget_kind_select",
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

  def budget_summary_section(target:, hidden:, aria_label:, body_hint:)
    section(
      class: [
        "flex shrink-0 flex-col rounded-xl border bg-card text-card-foreground shadow-sm",
        "min-h-[12rem]",
        ("hidden" if hidden)
      ].compact.join(" "),
      aria: { label: aria_label },
      data: { budgets_kind_target: target }
    ) do
      div(class: "border-b px-4 py-3") do
        div(class: "flex flex-col gap-0.5 sm:flex-row sm:items-baseline sm:justify-between") do
          h2(class: "text-sm font-medium") { "本月資料" }
          span(class: "text-xs text-muted-foreground tabular-nums") { current_month_label }
        end
      end
      div(class: "flex flex-col gap-4 p-4 sm:p-6") do
        p(class: "text-sm text-muted-foreground") { body_hint }
      end
    end
  end

  def revenue_budget_entry_section
    section(
      class: "rounded-xl border bg-card text-card-foreground shadow-sm shrink-0",
      aria: { label: "收入預算登錄" },
      data: { budgets_kind_target: "revenueEntry" }
    ) do
      div(class: "border-b px-4 py-3") do
        h2(class: "text-sm font-medium") { "登錄收入預算" }
      end
      div(class: "p-4 sm:p-6") do
        form(class: "mx-auto max-w-xl space-y-5", method: "post", action: "#") do
          input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
          input(type: "hidden", name: "revenue_budget[item]", value: "收入預算")

          budget_field_row(label: "金額：", id: "revenue_budget_amount") do
            budget_twd_amount_input(
              id: "revenue_budget_amount",
              name: "revenue_budget[amount]",
              placeholder: "0",
              required: true
            )
          end

          budget_field_row(label: "備註：", id: "revenue_budget_note") do
            Textarea(
              id: "revenue_budget_note",
              name: "revenue_budget[note]",
              rows: 3,
              placeholder: "選填"
            )
          end

          div(class: "flex gap-2 pt-1") do
            Button(type: :submit, variant: :primary, size: :md) { "儲存" }
            Button(type: :reset, variant: :outline, size: :md) { "清除" }
          end
        end
      end
    end
  end

  def expenditure_budget_entry_section
    section(
      class: "hidden rounded-xl border bg-card text-card-foreground shadow-sm shrink-0",
      aria: { label: "支出預算登錄" },
      data: { budgets_kind_target: "expenditureEntry" }
    ) do
      div(class: "border-b px-4 py-3") do
        h2(class: "text-sm font-medium") { "登錄支出預算" }
      end
      div(class: "p-4 sm:p-6") do
        form(class: "mx-auto max-w-xl space-y-5", method: "post", action: "#") do
          input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)

          budget_field_row(label: "類別：", id: "expenditure_budget_category") do
            div(class: "w-full min-w-0 [&>div]:w-full") do
              NativeSelect(
                id: "expenditure_budget_category",
                name: "expenditure_budget[category]",
                required: true
              ) do
                NativeSelectOption(value: "", disabled: true, selected: true) { plain "請選擇" }
                ExpenditureTaxonomy::CATEGORIES.each do |cat|
                  NativeSelectOption(value: cat) { plain cat }
                end
              end
            end
          end

          budget_field_row(label: "金額：", id: "expenditure_budget_amount") do
            budget_twd_amount_input(
              id: "expenditure_budget_amount",
              name: "expenditure_budget[amount]",
              placeholder: "0",
              required: true
            )
          end

          budget_field_row(label: "備註：", id: "expenditure_budget_note") do
            Textarea(
              id: "expenditure_budget_note",
              name: "expenditure_budget[note]",
              rows: 3,
              placeholder: "選填"
            )
          end

          div(class: "flex gap-2 pt-1") do
            Button(type: :submit, variant: :primary, size: :md) { "儲存" }
            Button(type: :reset, variant: :outline, size: :md) { "清除" }
          end
        end
      end
    end
  end

  def budget_field_row(label:, id:, &)
    div(class: "flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-4") do
      label(
        class: "shrink-0 text-sm font-medium leading-none sm:w-40 sm:pt-2 sm:text-right",
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
      div(class: "min-w-0 flex-1") do
        Input(
          **input_attrs,
          type: :text,
          inputmode: "decimal"
        )
      end
    end
  end

  def current_month_label
    t = Time.zone.today
    "#{t.year} 年 #{t.month} 月"
  end
end
