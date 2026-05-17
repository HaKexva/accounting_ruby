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
      settings_header

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

  def settings_header
    div(class: "space-y-2 pb-2 border-b border-border/60") do
      h1(class: PAGE_TITLE_CLASS) { "設定" }
      p(class: "max-w-prose text-sm leading-relaxed text-muted-foreground") do
        "管理支出表單使用的消費類別、支付方式與支付平台。"
      end
    end
  end

  def taxonomy_manager
    div(class: "w-full", data: { controller: "settings-taxonomy-kind" }) do
      taxonomy_kind_toolbar

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

  def taxonomy_kind_toolbar
    div(class: "flex flex-wrap items-center gap-x-2 gap-y-2 pb-4") do
      span(class: "text-base font-semibold tracking-tight text-foreground sm:text-lg") { "管理" }
      div(
        class: [
          "min-w-[10rem] max-w-full shrink-0 sm:max-w-[min(16rem,calc(100vw-6rem))]",
          "[&>div]:w-full sm:[&>div]:w-auto",
          "[&_select]:min-h-11 [&_select]:py-2 sm:[&_select]:min-h-9 sm:[&_select]:py-1"
        ].join(" ")
      ) do
        NativeSelect(
          id: "settings_taxonomy_kind_select",
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
  end

  def taxonomy_panel(kind:, target:, items:, hint:)
    hidden = @initial_kind != kind
    div(
      class: (hidden ? "hidden" : nil),
      data: { settings_taxonomy_kind_target: target }
    ) do
      section(class: CARD_SECTION_CLASS) do
        div(class: "border-b px-4 py-3 sm:px-5") do
          h2(class: "text-sm font-medium text-foreground") do
            plain ExpenditureTaxonomyItem::KIND_LABELS[kind]
          end
          p(class: "mt-1 text-xs leading-relaxed text-muted-foreground") { hint }
        end

        div(class: "divide-y divide-border/60") do
          if items.empty?
            p(class: "px-4 py-6 text-center text-sm text-muted-foreground sm:px-5") do
              "尚無項目，請在下方新增。"
            end
          else
            items.each { |item| taxonomy_item_row(item) }
          end
        end

        div(class: "border-t border-border/60 bg-muted/15 px-4 py-4 sm:px-5") do
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
    div(class: "flex items-center gap-1.5 px-4 py-3 sm:gap-3 sm:px-5") do
      form(
        class: "flex min-w-0 flex-1 items-center gap-1.5 sm:gap-3",
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
