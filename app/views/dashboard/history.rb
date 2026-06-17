# frozen_string_literal: true

class Views::Dashboard::History < Views::Base
  include Views::Dashboard::ActualExpenditureFormFields

  EDIT_FORM_ID = "history_edit_actual_expenditure_form"

  def initialize(actual_expenditures:, month_filter:, month_choices:, taxonomy:, filters: {})
    @actual_expenditures = actual_expenditures
    @month_filter = month_filter
    @month_choices = month_choices
    @taxonomy = taxonomy
    @filters = filters
  end

  def view_template
    div(
      class: "#{PAGE_SHELL} #{PAGE_NARROW_CLASS}",
      data: {
        controller: "expenditure-history expenditure-form"
      }
    ) do
      history_header
      history_records_section
      edit_modal
    end
  end

  private

  def history_header
    page_header(title: "歷史紀錄", subtitle: "瀏覽、編輯或刪除過去的支出") do
      Link(href: root_path(**dashboard_ym_params), variant: :outline, size: :md) { "返回實際支出" }
    end
  end

  def history_records_section
    section(class: "#{CARD_SECTION_CLASS} overflow-hidden", aria: { label: "實際支出列表" }) do
      div(class: MONTH_SUMMARY_HEADER_CLASS) do
        div(class: "flex flex-col gap-3") do
          div(class: "flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between") do
            h2(class: MONTH_SUMMARY_TITLE_CLASS) { history_list_title }
            calendar_month_selector(
              month_choices: @month_choices,
              calendar_month: @month_filter,
              url: expense_history_path,
              select_id: "history_calendar_month",
              include_all: true,
              compact: true
            )
          end
          history_filter_form
        end
      end

      if @actual_expenditures.empty?
        empty_list_body
      else
        ul(class: "divide-y divide-border/60", role: "list") do
          @actual_expenditures.each do |expenditure|
            history_list_item(expenditure)
          end
        end
      end
    end
  end

  def empty_list_body
    div(class: "flex flex-col items-center px-6 py-14 text-center sm:py-16") do
      div(class: "mb-4 flex size-14 items-center justify-center rounded-full bg-muted/60 text-muted-foreground") do
        empty_icon
      end
      if @month_filter
        p(class: "text-base font-semibold text-foreground") { "此月份尚無紀錄" }
        p(class: "mt-2 max-w-sm text-sm text-muted-foreground") do
          "可改選其他月份，或選擇「全部月份」瀏覽所有支出。"
        end
      else
        p(class: "text-base font-semibold text-foreground") { "尚無歷史紀錄" }
        p(class: "mt-2 max-w-sm text-sm text-muted-foreground") do
          "在實際支出頁登錄第一筆支出後，會顯示在這裡。"
        end
        div(class: "mt-6") do
          Link(href: root_path, variant: :primary, size: :md) { "前往登錄支出" }
        end
      end
    end
  end

  def history_filter_form
    form(
      action: expense_history_path,
      method: :get,
      class: "grid grid-cols-1 gap-2 sm:grid-cols-2"
    ) do
      ym = calendar_month_ym_for(@month_filter)
      input(type: :hidden, name: :ym, value: ym) if ym.present?

      Input(
        name: "q",
        type: :search,
        value: @filters[:q].to_s,
        placeholder: "搜尋（項目／備註／類別）…",
        class: "sm:col-span-2"
      )

      NativeSelect(
        name: "category",
        aria: { label: "消費類別" }
      ) do
        NativeSelectOption(value: "", selected: @filters[:category].blank?) { plain "全部類別" }
        @taxonomy.categories.each do |c|
          NativeSelectOption(value: c, selected: @filters[:category].to_s == c) { plain c }
        end
      end

      NativeSelect(
        name: "payment_method",
        aria: { label: "支付方式" }
      ) do
        NativeSelectOption(value: "", selected: @filters[:payment_method].blank?) { plain "全部支付方式" }
        @taxonomy.payment_methods.each do |m|
          NativeSelectOption(value: m, selected: @filters[:payment_method].to_s == m) { plain m }
        end
      end

      NativeSelect(
        name: "payment_platform",
        aria: { label: "支付平台" }
      ) do
        NativeSelectOption(value: "", selected: @filters[:payment_platform].blank?) { plain "全部支付平台" }
        @taxonomy.payment_platforms.each do |p|
          NativeSelectOption(value: p, selected: @filters[:payment_platform].to_s == p) { plain p }
        end
      end

      div(class: "grid grid-cols-2 gap-2") do
        Input(
          name: "date_from",
          type: :date,
          value: @filters[:date_from].to_s,
          aria: { label: "起始日期" }
        )
        Input(
          name: "date_to",
          type: :date,
          value: @filters[:date_to].to_s,
          aria: { label: "結束日期" }
        )
      end

      div(class: "grid grid-cols-2 gap-2") do
        Input(
          name: "min_posted_amount",
          type: :text,
          inputmode: "numeric",
          value: @filters[:min_posted_amount].to_s,
          placeholder: "最小列帳金額",
          aria: { label: "最小列帳金額" }
        )
        Input(
          name: "max_posted_amount",
          type: :text,
          inputmode: "numeric",
          value: @filters[:max_posted_amount].to_s,
          placeholder: "最大列帳金額",
          aria: { label: "最大列帳金額" }
        )
      end

      div(class: "flex gap-2 sm:col-span-2") do
        Button(type: :submit, variant: :primary, size: :sm, class: "flex-1") { "篩選" }
        Link(href: clear_filter_href, variant: :outline, size: :sm, class: "flex-1") { "清除" }
      end
    end
  end

  def clear_filter_href
    ym = calendar_month_ym_for(@month_filter)
    ym.present? ? expense_history_path(ym: ym) : expense_history_path
  end

  def history_list_item(expenditure)
    li(
      class: "list-none",
      data: {
        expenditure_history_target: "listItem",
        expenditure_id: expenditure.id,
        # Base64 JSON：避免 HTML 屬性內的特殊字元導致 Stimulus 無法解析。
        expenditure_history_record_param: record_data_json(expenditure)
      }
    ) do
      div(
        class: [
          "flex items-center justify-between gap-3 px-4 py-3.5 sm:px-5",
          "transition-colors hover:bg-muted/30"
        ].join(" ")
      ) do
        div(
          class: "min-w-0 flex-1 cursor-pointer space-y-1",
          data: {
            expenditure_history_target: "listItemBody",
            expenditure_history_action: "open-edit"
          }
        ) do
          history_list_item_body(expenditure)
        end
        div(class: "flex shrink-0 items-center gap-2") do
          Button(
            type: :button,
            variant: :outline,
            size: :sm,
            data: { expenditure_history_action: "open-edit" }
          ) { "編輯" }
          Button(
            type: :button,
            variant: :outline,
            size: :sm,
            class: "text-destructive border-destructive/40 hover:bg-destructive/10 hover:text-destructive",
            data: { expenditure_history_action: "destroy" }
          ) { "刪除" }
        end
      end
    end
  end

  def history_list_item_body(expenditure)
    p(class: "text-xs font-medium uppercase tracking-wide text-muted-foreground tabular-nums") do
      expenditure.transaction_date.strftime("%Y-%m-%d")
    end
    p(class: "mt-1 text-base font-semibold text-foreground truncate") do
      item_title(expenditure)
    end
    if expenditure.category.present?
      span(
        class: [
          "mt-2 inline-block max-w-full truncate rounded-md border border-border/60",
          "bg-muted/40 px-2 py-0.5 text-xs text-muted-foreground"
        ].join(" ")
      ) { expenditure.category }
    end
    p(class: "mt-2 text-sm font-semibold tabular-nums text-destructive") do
      plain "NT$ #{format_decimal(expenditure.posted_amount)}"
    end
  end

  def empty_icon
    svg(
      xmlns: "http://www.w3.org/2000/svg",
      width: "28",
      height: "28",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      stroke_width: "1.5",
      stroke_linecap: "round",
      stroke_linejoin: "round",
      aria: { hidden: true }
    ) do |s|
      s.path(d: "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8")
      s.path(d: "M3 3v5h5")
    end
  end

  def edit_modal
    div(
      class: "hidden fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4",
      data: { expenditure_history_target: "modal" },
      role: "dialog",
      aria: { modal: true, labelledby: "history-edit-title" }
    ) do
      div(
        class: "absolute inset-0 bg-background/80 backdrop-blur-sm",
        data: { action: "click->expenditure-history#close" },
        aria: { hidden: true }
      )

      div(
        class: [
          "relative z-10 flex max-h-[min(92dvh,40rem)] w-full flex-col",
          "overflow-hidden rounded-t-xl border bg-card shadow-lg sm:max-w-lg sm:rounded-xl"
        ].join(" ")
      ) do
        div(class: "flex items-center justify-between border-b px-4 py-3 sm:px-5") do
          h2(id: "history-edit-title", class: "text-base font-semibold") { "編輯支出" }
          button(
            type: "button",
            class: "rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground",
            aria: { label: "關閉" },
            data: { action: "click->expenditure-history#close" }
          ) { plain "✕" }
        end

        div(class: "min-h-0 flex-1 overflow-y-auto px-4 py-4 sm:px-5 sm:py-5") do
          form(
            id: EDIT_FORM_ID,
            class: "space-y-5",
            data: {
              expenditure_history_target: "editForm",
              action: "submit->expenditure-history#save"
            }
          ) do
            input(
              type: "hidden",
              name: "authenticity_token",
              value: view_context.form_authenticity_token
            )

            p(
              class: "hidden rounded-md border border-border/60 bg-muted/40 px-2 py-1.5 text-[11px] text-foreground",
              data: { expenditure_history_target: "status" }
            ) { plain "" }

            edit_form_fields
          end
        end

        div(class: "flex gap-2 border-t px-4 py-3 sm:px-5") do
          Button(
            type: :button,
            variant: :outline,
            size: :md,
            class: "flex-1",
            data: { action: "click->expenditure-history#close" }
          ) { "取消" }
          Button(
            type: :submit,
            variant: :primary,
            size: :md,
            class: "flex-1",
            form: EDIT_FORM_ID
          ) { "儲存" }
        end
      end
    end
  end

  def edit_form_fields
    expenditure_field_row(label: "日期：", id: "history_edit_transaction_date") do
      Input(
        id: "history_edit_transaction_date",
        name: "actual_expenditure[transaction_date]",
        type: :date,
        form: EDIT_FORM_ID,
        required: true
      )
    end

    expenditure_field_row(label: "項目：", id: "history_edit_transaction_item") do
      div(class: "min-w-0 flex-1 max-sm:[&_input]:min-h-11") do
        Input(
          id: "history_edit_transaction_item",
          name: "actual_expenditure[transaction_item]",
          type: :text,
          form: EDIT_FORM_ID,
          placeholder: "輸入項目名稱...",
          required: true
        )
      end
    end

    expenditure_select_row(
      label: "消費類別：",
      id: "history_edit_category",
      name: "actual_expenditure[category]",
      options: @taxonomy.categories,
      required: true,
      prompt: "請選擇",
      form: EDIT_FORM_ID
    )

    expenditure_select_row(
      label: "支付方式：",
      id: "history_edit_payment_method",
      name: "actual_expenditure[payment_method]",
      options: @taxonomy.payment_methods,
      required: true,
      prompt: "請選擇",
      form: EDIT_FORM_ID,
      native_select: {
        data: {
          expenditure_form_target: "paymentMethod",
          action: "change->expenditure-form#paymentMethodChanged"
        }
      }
    )

    div(
      class: "hidden flex flex-col gap-5",
      data: { expenditure_form_target: "creditCardSection" }
    ) do
      expenditure_select_row(
        label: "信用卡支付方式：",
        id: "history_edit_credit_card_payment_method",
        name: "actual_expenditure[credit_card_payment_method]",
        options: ExpenditureTaxonomy::CREDIT_CARD_PAYMENT_KINDS,
        required: false,
        prompt: "請選擇",
        include_blank: false,
        form: EDIT_FORM_ID,
        native_select: {
          disabled: true,
          data: { expenditure_form_target: "creditCardPaymentMethod" }
        }
      )

      expenditure_select_row(
        label: "本月／次月支付：",
        id: "history_edit_payment_timing",
        name: "actual_expenditure[payment_timing]",
        options: ExpenditureTaxonomy::PAYMENT_TIMINGS,
        prompt: "請選擇",
        form: EDIT_FORM_ID,
        native_select: {
          disabled: true,
          data: { expenditure_form_target: "paymentTiming" }
        }
      )
    end

    div(class: "hidden", data: { expenditure_form_target: "paymentPlatformSection" }) do
      expenditure_select_row(
        label: "支付平台：",
        id: "history_edit_payment_platform",
        name: "actual_expenditure[payment_platform]",
        options: @taxonomy.payment_platforms,
        prompt: "請選擇",
        form: EDIT_FORM_ID,
        native_select: {
          disabled: true,
          data: { expenditure_form_target: "paymentPlatform" }
        }
      )
    end

    expenditure_field_row(label: "實際消費金額（TWD）：", id: "history_edit_actual_amount") do
      twd_amount_input(
        id: "history_edit_actual_amount",
        name: "actual_expenditure[actual_amount]",
        form: EDIT_FORM_ID,
        placeholder: "0",
        required: true
      )
    end

    expenditure_field_row(label: "列帳消費金額（TWD）：", id: "history_edit_posted_amount") do
      twd_amount_input(
        id: "history_edit_posted_amount",
        name: "actual_expenditure[posted_amount]",
        form: EDIT_FORM_ID,
        placeholder: "0",
        required: true
      )
    end

    expenditure_field_row(label: "備註：", id: "history_edit_note") do
      Textarea(
        id: "history_edit_note",
        name: "actual_expenditure[note]",
        form: EDIT_FORM_ID,
        rows: 3,
        placeholder: "選填"
      )
    end
  end

  def record_data_json(expenditure)
    Base64.strict_encode64(record_data(expenditure).to_json)
  end

  def record_data(expenditure)
    {
      id: expenditure.id,
      transaction_date: expenditure.transaction_date.iso8601,
      transaction_item: expenditure.transaction_item,
      category: expenditure.category,
      payment_method: expenditure.payment_method,
      credit_card_payment_method: expenditure.credit_card_payment_method,
      payment_timing: expenditure.payment_timing,
      payment_platform: expenditure.payment_platform,
      actual_amount: format_decimal(expenditure.actual_amount),
      posted_amount: format_decimal(expenditure.posted_amount),
      note: expenditure.note.to_s
    }
  end

  def item_title(expenditure)
    expenditure.transaction_item.presence || "(無標題)"
  end

  def history_list_title
    if @month_filter
      "#{calendar_month_label_for(@month_filter)}紀錄"
    else
      "全部紀錄"
    end
  end

  def dashboard_ym_params
    ym = calendar_month_ym_for(@month_filter)
    ym.present? ? { ym: ym } : {}
  end
end
