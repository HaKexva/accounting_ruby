# frozen_string_literal: true

class Views::Dashboard::History < Views::Base
  include Views::Dashboard::ActualExpenditureFormFields

  EDIT_FORM_ID = "history_edit_actual_expenditure_form"

  def initialize(actual_expenditures:)
    @actual_expenditures = actual_expenditures
  end

  def view_template
    div(
      class: "#{PAGE_SHELL} #{PAGE_NARROW_CLASS}",
      data: {
        controller: "expenditure-history expenditure-form"
      }
    ) do
      history_header

      if @actual_expenditures.empty?
        empty_state
      else
        expenditures_list
      end

      edit_modal
    end
  end

  private

  def history_header
    div(class: PAGE_HEADER_ROW_CLASS) do
      div(class: "min-w-0 flex-1 pr-2") do
        h1(class: PAGE_TITLE_CLASS) { "歷史紀錄" }
      end
      div(class: "flex shrink-0 pt-0.5") do
        Link(href: root_path, variant: :outline, size: :md) { "返回實際支出" }
      end
    end
  end

  def empty_state
    section(class: "#{CARD_SECTION_CLASS} overflow-hidden", aria: { label: "實際支出列表" }) do
      p(class: "py-10 text-center text-sm text-muted-foreground") { "尚無歷史紀錄" }
    end
  end

  def expenditures_list
    section(class: "#{CARD_SECTION_CLASS} overflow-hidden", aria: { label: "實際支出列表" }) do
      div(class: MONTH_SUMMARY_HEADER_CLASS) do
        h2(class: MONTH_SUMMARY_TITLE_CLASS) { "全部紀錄" }
      end
      ul(class: "divide-y divide-border/60", role: "list") do
        @actual_expenditures.each do |expenditure|
          history_list_item(expenditure)
        end
      end
    end
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
          "flex items-center justify-between gap-3 px-4 py-3 sm:px-5",
          "transition-colors hover:bg-muted/40"
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
    p(class: "text-sm text-muted-foreground tabular-nums") do
      expenditure.transaction_date.strftime("%Y-%m-%d")
    end
    p(class: "text-base font-medium text-foreground truncate") do
      item_title(expenditure)
    end
    if expenditure.category.present?
      p(class: "text-sm text-muted-foreground truncate") do
        plain "類別：#{expenditure.category}"
      end
    end
    p(class: "text-sm font-medium tabular-nums text-destructive") do
      plain "金額：#{format_decimal(expenditure.posted_amount)}"
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
      options: ExpenditureTaxonomy::CATEGORIES,
      required: true,
      prompt: "請選擇",
      form: EDIT_FORM_ID
    )

    expenditure_select_row(
      label: "支付方式：",
      id: "history_edit_payment_method",
      name: "actual_expenditure[payment_method]",
      options: ExpenditureTaxonomy::PAYMENT_METHODS,
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
        include_blank: true,
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
        options: ExpenditureTaxonomy::PAYMENT_PLATFORMS,
        include_blank: true,
        form: EDIT_FORM_ID,
        native_select: {
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
end
