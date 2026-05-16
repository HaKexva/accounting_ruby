# frozen_string_literal: true

class Views::Dashboard::History < Views::Base
  def initialize(actual_expenditures:)
    @actual_expenditures = actual_expenditures
  end

  def view_template
    div(class: PAGE_SHELL) do
      div(
        class: [
          "flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between shrink-0",
          "pb-6 border-b border-border/60"
        ].join(" ")
      ) do
        div(class: "min-w-0 flex-1 space-y-2") do
          h1(class: "text-balance text-2xl font-semibold tracking-tight sm:text-3xl") { "歷史紀錄" }
          p(class: "max-w-prose text-sm leading-relaxed text-muted-foreground") do
            plain "所有已登錄的實際支出（依交易日期新到舊）。"
          end
        end
        div(class: "flex shrink-0 sm:pt-1") do
          Link(href: root_path, variant: :outline, size: :md) { "返回實際支出" }
        end
      end

      div(class: "mt-8 shrink-0") do
        if @actual_expenditures.empty?
          empty_state
        else
          expenditures_table
        end
      end
    end
  end

  private

  def empty_state
    div(
      class: [
        "rounded-2xl border-2 border-dashed border-border/60 bg-gradient-to-b from-muted/50 to-muted/10",
        "px-8 py-14 text-center shadow-inner sm:px-12 sm:py-16"
      ].join(" ")
    ) do
      p(class: "text-base font-semibold text-foreground") { "尚無資料" }
      p(class: "mx-auto mt-2 max-w-sm text-sm leading-relaxed text-muted-foreground") do
        "目前還沒有任何實際支出紀錄。"
      end
    end
  end

  def expenditures_table
    section(
      class: [
        "rounded-xl border bg-card text-card-foreground shadow-sm ring-1 ring-border/40",
        "overflow-hidden"
      ],
      aria: { label: "實際支出列表" }
    ) do
      Table do
        TableHeader(class: "[&_tr]:bg-muted/45 [&_th]:font-semibold [&_th]:text-foreground/90") do
          TableRow do
            TableHead(class: "whitespace-nowrap") { "日期" }
            TableHead(class: "whitespace-nowrap") { "帳務月份" }
            TableHead(class: "whitespace-nowrap") { "類別" }
            TableHead(class: "whitespace-nowrap") { "項目" }
            TableHead(class: "whitespace-nowrap") { "支付方式" }
            TableHead(class: "whitespace-nowrap") { "信用卡支付" }
            TableHead(class: "whitespace-nowrap") { "本月／次月支付" }
            TableHead(class: "whitespace-nowrap") { "支付平台" }
            TableHead(class: "whitespace-nowrap text-right tabular-nums") { "實際金額" }
            TableHead(class: "whitespace-nowrap text-right tabular-nums") { "列帳金額" }
            TableHead(class: "min-w-[12rem] max-w-md") { "備註" }
          end
        end
        TableBody do
          @actual_expenditures.each do |expenditure|
            expenditure_row(expenditure)
          end
        end
      end
    end
  end

  def expenditure_row(expenditure)
    cm = expenditure.calendar_month
    month_label = "#{cm.year} 年 #{cm.month} 月"

    TableRow do
      TableCell(class: "whitespace-nowrap tabular-nums text-muted-foreground") do
        expenditure.transaction_date.strftime("%Y-%m-%d")
      end
      TableCell(class: "whitespace-nowrap tabular-nums text-muted-foreground") { month_label }
      TableCell(class: "font-medium") { expenditure.category }
      TableCell { display_optional(expenditure.transaction_item) }
      TableCell { expenditure.payment_method }
      TableCell { display_optional(expenditure.credit_card_payment_method) }
      TableCell { display_optional(expenditure.payment_timing) }
      TableCell { display_optional(expenditure.payment_platform) }
      TableCell(class: "whitespace-nowrap text-right tabular-nums") { format_decimal(expenditure.actual_amount) }
      TableCell(class: "whitespace-nowrap text-right tabular-nums") { format_decimal(expenditure.posted_amount) }
      TableCell(class: "max-w-md break-words text-muted-foreground") do
        display_optional(expenditure.note)
      end
    end
  end

  def display_optional(value)
    v = value.presence
    v ? plain(v.to_s) : plain("—")
  end

  def format_decimal(amount)
    format("%.2f", amount.to_d)
  end
end
