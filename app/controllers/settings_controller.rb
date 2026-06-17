# frozen_string_literal: true

class SettingsController < ApplicationController
  def index
    user = trial_account_owner
    unless user
      render Views::Settings::Index.new(
        taxonomy_available: false,
        items_by_kind: {},
        initial_kind: "category"
      )
      return
    end

    unless ExpenditureTaxonomy.persisted_taxonomy_available?
      render Views::Settings::Index.new(
        taxonomy_available: false,
        items_by_kind: {},
        initial_kind: "category"
      )
      return
    end

    ExpenditureTaxonomy.ensure_seeded!(user)
    kind = valid_kind(params[:kind])
    items_by_kind = ExpenditureTaxonomyItem::KINDS.index_with do |k|
      ExpenditureTaxonomyItem.for_kind(k).where(user: user).to_a
    end

    render Views::Settings::Index.new(
      taxonomy_available: true,
      items_by_kind: items_by_kind,
      initial_kind: kind
    )
  end

  def create_taxonomy_item
    user = require_taxonomy_user!
    return unless user
    return unless require_persisted_taxonomy!

    item = user.expenditure_taxonomy_items.build(taxonomy_item_attributes)
    item.position = next_position_for(user, item.kind)

    if item.save
      redirect_to settings_path(kind: item.kind), notice: "已新增「#{item.name}」。"
    else
      redirect_to settings_path(kind: taxonomy_item_attributes[:kind]),
                  alert: item.errors.full_messages.to_sentence.presence || "無法新增。"
    end
  end

  def update_taxonomy_item
    user = require_taxonomy_user!
    return unless user
    return unless require_persisted_taxonomy!

    item = user.expenditure_taxonomy_items.find(params[:id])
    previous_name = item.name
    if item.update(taxonomy_item_attributes.except(:kind))
      synced = ExpenditureTaxonomyRenamePropagator.call(
        user: user,
        kind: item.kind,
        from: previous_name,
        to: item.name
      )
      notice = "#{notice} 已同步本月 #{synced} 筆支出與預算資料。" if synced.positive?
      redirect_to settings_path(kind: item.kind), notice: notice
    else
      redirect_to settings_path(kind: item.kind),
                  alert: item.errors.full_messages.to_sentence.presence || "無法更新。"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to settings_path, alert: "找不到此選項。"
  end

  def destroy_taxonomy_item
    user = require_taxonomy_user!
    return unless user
    return unless require_persisted_taxonomy!

    item = user.expenditure_taxonomy_items.find(params[:id])
    kind = item.kind
    name = item.name
    if item.destroy
      redirect_to settings_path(kind: kind), notice: "已刪除「#{name}」。"
    else
      redirect_to settings_path(kind: kind), alert: "無法刪除此選項。"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to settings_path, alert: "找不到此選項。"
  end

  private

  def require_taxonomy_user!
    user = trial_account_owner
    unless user
      redirect_to settings_path, alert: "無法準備試用環境，請稍後再試。"
      return nil
    end
    user
  end

  def require_persisted_taxonomy!
    return true if ExpenditureTaxonomy.persisted_taxonomy_available?

    redirect_to settings_path, alert: "資料庫尚未更新，請重新部署或執行 bin/rails db:prepare。"
    false
  end

  def valid_kind(raw)
    kind = raw.to_s
    ExpenditureTaxonomyItem::KINDS.include?(kind) ? kind : "category"
  end

  def taxonomy_item_attributes
    raw = params.require(:expenditure_taxonomy_item).permit(:kind, :name)
    {
      kind: valid_kind(raw[:kind]),
      name: raw[:name].to_s.strip
    }
  end

  def next_position_for(user, kind)
    user.expenditure_taxonomy_items.where(kind: kind).maximum(:position).to_i + 1
  end
end
