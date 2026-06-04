# frozen_string_literal: true

module Views::Dashboard::ActualExpenditureFormFields
  LIVE_SUMMARY_RECALC_ACTIONS = [
    "input->expenditure-live-category-summary#recalc",
    "change->expenditure-live-category-summary#recalc"
  ].freeze

  private

  def live_summary_category_select_data(extra = {})
    live_summary_select_data(extra)
  end

  def live_summary_amount_input_data(extra = {})
    live_summary_input_data(extra)
  end

  def live_summary_select_data(extra = {})
    {
      ruby_ui__form_field_target: "input",
      action: [
        "change->ruby-ui--form-field#onChange",
        "invalid->ruby-ui--form-field#onInvalid",
        *LIVE_SUMMARY_RECALC_ACTIONS
      ].join(" "),
      **extra
    }
  end

  def live_summary_input_data(extra = {})
    {
      ruby_ui__form_field_target: "input",
      action: [
        "input->ruby-ui--form-field#onInput",
        "invalid->ruby-ui--form-field#onInvalid",
        *LIVE_SUMMARY_RECALC_ACTIONS
      ].join(" "),
      **extra
    }
  end

  def expenditure_select_row(label:, id:, name:, options:, required: false, prompt: nil, include_blank: false,
                           form: nil, native_select: {}, selected: nil, live_summary: false)
    expenditure_field_row(label: label, id: id) do
      div(class: "w-full min-w-0 [&>div]:w-full") do
        sel_attrs = { id: id, name: name, required: required, **native_select }
        if live_summary
          sel_data = sel_attrs[:data].is_a?(Hash) ? sel_attrs[:data] : {}
          sel_attrs[:data] = live_summary_category_select_data(sel_data)
        end
        sel_attrs[:form] = form if form
        NativeSelect(**sel_attrs) do
          if prompt
            NativeSelectOption(value: "", disabled: true, selected: selected.blank?) { plain prompt }
          elsif include_blank
            NativeSelectOption(value: "", selected: selected.blank?) { plain "（不適用／選填）" }
          end
          options.each do |value|
            NativeSelectOption(value: value, selected: selected == value) { plain value }
          end
        end
      end
    end
  end

  def twd_amount_input(live_summary: false, **input_attrs)
    if live_summary
      input_data = input_attrs[:data].is_a?(Hash) ? input_attrs[:data] : {}
      input_attrs = input_attrs.merge(data: live_summary_amount_input_data(input_data))
    end

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

  def format_decimal(amount)
    Kernel.format("%.0f", amount.to_d.round)
  end
end
