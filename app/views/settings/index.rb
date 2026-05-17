# frozen_string_literal: true

class Views::Settings::Index < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(taxonomy_available:, items_by_kind:, initial_kind:)
    @taxonomy_available = taxonomy_available
    @items_by_kind = items_by_kind
    @initial_kind = initial_kind
  end

  def view_template
    div(class: "#{PAGE_SHELL} space-y-6") do
      page_header(
        title: "設定",
        subtitle: "管理支出表單使用的消費類別、支付方式與支付平台。"
      )

      if @taxonomy_available
        taxonomy_manager
      else
        render Views::PlaceholderPanel.new(
          heading: "無法載入設定",
          hint: "資料庫尚未套用最新 migration。請在 Railway 執行 bin/rails db:prepare 或重新部署後再試。"
        )
      end
    end
  end

  private

  def taxonomy_manager
    div(class: "w-full space-y-5", data: { controller: "settings-taxonomy-kind" }) do
      taxonomy_kind_switcher

      taxonomy_panel(
        kind: "category",
        target: "categoryPanel",
        items: @items_by_kind.fetch("category", []),
        hint: "用於實際支出與支出預算的類別選單。"
      )
      taxonomy_panel(
        kind: "payment_method",
        target: "paymentMethodPanel",
        items: @items_by_kind.fetch("payment_method", []),
        hint: "用於實際支出的支付方式選單。"
      )
      taxonomy_panel(
        kind: "payment_platform",
        target: "paymentPlatformPanel",
        items: @items_by_kind.fetch("payment_platform", []),
        hint: "選擇「多元支付」時顯示的平台選單。"
      )
    end
  end

  def taxonomy_kind_switcher
    div(class: "space-y-2") do
      span(class: "text-xs font-medium uppercase tracking-wide text-muted-foreground") { "管理項目" }
      div(
        class: SEGMENTED_CONTROL_CLASS,
        role: "group",
        aria: { label: "設定類型" },
        data: { settings_taxonomy_kind_target: "track" }
      ) do
        span(
          class: SEGMENTED_CONTROL_INDICATOR_CLASS,
          data: { settings_taxonomy_kind_target: "indicator" },
          aria: { hidden: true }
        )
        ExpenditureTaxonomyItem::KINDS.each do |kind|
          kind_segment_button(kind)
        end
      end
      NativeSelect(
        id: "settings_taxonomy_kind_select",
        class: "sr-only",
        aria: { label: "設定類型" },
        data: {
          settings_taxonomy_kind_target: "kindSelect",
          action: "change->settings-taxonomy-kind#sync"
        }
      ) do
        ExpenditureTaxonomyItem::KINDS.each do |kind|
          NativeSelectOption(
            value: kind,
            selected: @initial_kind == kind
          ) { plain ExpenditureTaxonomyItem::KIND_LABELS[kind] }
        end
      end
    end
  end

  def kind_segment_button(kind)
    active = @initial_kind == kind
    button(
      type: "button",
      class: [
        SEGMENTED_CONTROL_BTN_CLASS,
        (active ? SEGMENTED_CONTROL_BTN_ACTIVE_CLASS : nil)
      ].compact.join(" "),
      data: {
        kind_value: kind,
        settings_taxonomy_kind_target: "kindButton",
        action: "click->settings-taxonomy-kind#pickKind"
      },
      aria: { pressed: active }
    ) { ExpenditureTaxonomyItem::KIND_LABELS[kind] }
  end

  def taxonomy_panel(kind:, target:, items:, hint:)
    hidden = @initial_kind != kind
    div(
      class: (hidden ? "hidden" : nil),
      data: { settings_taxonomy_kind_target: target }
    ) do
      section(class: CARD_SECTION_CLASS) do
        div(class: "border-b border-border/60 bg-muted/15 px-4 py-3.5 sm:px-5") do
          h2(class: "text-sm font-semibold text-foreground") do
            plain ExpenditureTaxonomyItem::KIND_LABELS[kind]
          end
          p(class: "mt-1 text-xs leading-relaxed text-muted-foreground") { hint }
        end

        div(class: "divide-y divide-border/50") do
          if items.empty?
            div(class: "px-4 py-10 text-center sm:px-5") do
              p(class: "text-sm font-medium text-foreground") { "尚無項目" }
              p(class: "mt-1 text-xs text-muted-foreground") { "請在下方新增第一筆。" }
            end
          else
            items.each { |item| taxonomy_item_row(item) }
          end
        end

        div(class: "border-t border-border/60 bg-muted/10 px-4 py-4 sm:px-5") do
          taxonomy_add_form(kind: kind)
        end
      end
    end
  end

  SETTINGS_ROW_ACTION_BTN_CLASS = [
    "shrink-0 shadow-sm",
    "h-8 px-2.5 text-xs",
    "sm:h-9 sm:px-4 sm:py-2 sm:text-sm"
  ].join(" ").freeze

  def taxonomy_item_row(item)
    div(
      class: [
        "flex items-center gap-2 px-4 py-3 transition-colors sm:gap-3 sm:px-5",
        "hover:bg-muted/25"
      ].join(" ")
    ) do
      form(
        class: "flex min-w-0 flex-1 items-center gap-2 sm:gap-3",
        action: settings_taxonomy_item_path(item),
        method: "post",
        data: {
          controller: "settings-taxonomy-row",
          action: "input->settings-taxonomy-row#sync change->settings-taxonomy-row#sync"
        }
      ) do
        input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
        input(type: "hidden", name: "_method", value: "patch")
        input(type: "hidden", name: "expenditure_taxonomy_item[kind]", value: item.kind)

        div(class: "min-w-0 flex-1") do
          Input(
            id: "taxonomy_item_name_#{item.id}",
            name: "expenditure_taxonomy_item[name]",
            type: :text,
            value: item.name,
            required: true,
            aria: { label: "名稱" },
            data: { settings_taxonomy_row_target: "nameInput" }
          )
        end

        Button(
          type: :submit,
          variant: :secondary,
          size: :sm,
          class: "#{SETTINGS_ROW_ACTION_BTN_CLASS} opacity-40 pointer-events-none",
          disabled: true,
          aria: { disabled: true },
          data: { settings_taxonomy_row_target: "submitButton" }
        ) { "儲存" }
      end

      form(method: "post", action: delete_settings_taxonomy_item_path(item), class: "shrink-0") do
        input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
        input(type: "hidden", name: "_method", value: "delete")
        Button(
          type: :submit,
          variant: :destructive,
          size: :sm,
          class: SETTINGS_ROW_ACTION_BTN_CLASS,
          data: { turbo_confirm: "確定刪除「#{item.name}」？" }
        ) { "刪除" }
      end
    end
  end

  def taxonomy_add_form(kind:)
    form(
      class: "flex flex-col gap-3 sm:flex-row sm:items-end",
      action: settings_taxonomy_items_path,
      method: "post",
      data: {
        controller: "settings-taxonomy-row",
        settings_taxonomy_row_mode_value: "add",
        action: "input->settings-taxonomy-row#sync change->settings-taxonomy-row#sync"
      }
    ) do
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      input(type: "hidden", name: "expenditure_taxonomy_item[kind]", value: kind)

      div(class: "min-w-0 flex-1 space-y-1.5") do
        label(
          for: "taxonomy_new_name_#{kind}",
          class: "text-xs font-medium text-muted-foreground"
        ) { "新增項目" }
        Input(
          id: "taxonomy_new_name_#{kind}",
          name: "expenditure_taxonomy_item[name]",
          type: :text,
          placeholder: "輸入名稱…",
          required: true,
          data: { settings_taxonomy_row_target: "nameInput" }
        )
      end

      Button(
        type: :submit,
        variant: :primary,
        size: :md,
        class: "shrink-0 shadow-sm opacity-40 pointer-events-none",
        disabled: true,
        aria: { disabled: true },
        data: { settings_taxonomy_row_target: "submitButton" }
      ) { "新增" }
    end
  end
end
