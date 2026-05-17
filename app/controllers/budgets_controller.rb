# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :set_budget_context, only: %i[
    create_revenue_budget update_revenue_budget destroy_revenue_budget
    create_expenditure_budget update_expenditure_budget destroy_expenditure_budget
  ]

  def index
    user = trial_account_owner
    revenue_budgets, expenditure_budgets, calendar_month = budget_index_state
    focus = carousel_focus_from_params(revenue_budgets, expenditure_budgets)

    taxonomy = ExpenditureTaxonomy.for_user(user)

    render Views::Budgets::Index.new(
      revenue_budgets: revenue_budgets,
      expenditure_budgets: expenditure_budgets,
      calendar_month: calendar_month,
      initial_budget_kind: focus.fetch(:kind),
      revenue_carousel_initial_index: focus[:revenue_index],
      expenditure_carousel_initial_index: focus[:expenditure_index],
      taxonomy: taxonomy
    )
  end

  def create_revenue_budget
    budget = @calendar_month.revenue_budgets.build(revenue_budget_attributes.merge(user: @user))
    if budget.save
      respond_to do |format|
        format.json { render json: { ok: true, id: budget.id } }
        format.html { redirect_to budgets_path, notice: "已儲存收入預算。" }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, errors: budget.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to budgets_path, alert: budget.errors.full_messages.to_sentence.presence || "無法儲存收入預算。" }
      end
    end
  end

  def update_revenue_budget
    budget = revenue_scope.find(params[:id])
    if budget.update(revenue_budget_attributes)
      respond_to do |format|
        format.json { render json: { ok: true, id: budget.id } }
        format.html { redirect_to budgets_path, notice: "已更新收入預算。" }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, errors: budget.errors.full_messages }, status: :unprocessable_entity }
        format.html do
          redirect_to budgets_path(revenue_focus: budget.id),
                      alert: budget.errors.full_messages.to_sentence.presence || "無法更新收入預算。"
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { ok: false, errors: [ "找不到此筆收入預算。" ] }, status: :not_found }
      format.html { redirect_to budgets_path, alert: "找不到此筆收入預算。" }
    end
  end

  def destroy_revenue_budget
    budget = revenue_scope.find(params[:id])
    if budget.destroy
      redirect_to budgets_path, notice: "已刪除收入預算。"
    else
      redirect_to budgets_path, alert: "無法刪除此筆收入預算。"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: "找不到此筆收入預算。"
  end

  def create_expenditure_budget
    budget = @calendar_month.expenditure_budgets.build(expenditure_budget_attributes.merge(user: @user))
    if budget.save
      respond_to do |format|
        format.json { render json: { ok: true, id: budget.id } }
        format.html { redirect_to budgets_path, notice: "已儲存支出預算。" }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, errors: budget.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to budgets_path, alert: budget.errors.full_messages.to_sentence.presence || "無法儲存支出預算。" }
      end
    end
  end

  def update_expenditure_budget
    budget = expenditure_scope.find(params[:id])
    if budget.update(expenditure_budget_attributes)
      respond_to do |format|
        format.json { render json: { ok: true, id: budget.id } }
        format.html { redirect_to budgets_path, notice: "已更新支出預算。" }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, errors: budget.errors.full_messages }, status: :unprocessable_entity }
        format.html do
          redirect_to budgets_path(expenditure_focus: budget.id),
                      alert: budget.errors.full_messages.to_sentence.presence || "無法更新支出預算。"
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { ok: false, errors: [ "找不到此筆支出預算。" ] }, status: :not_found }
      format.html { redirect_to budgets_path, alert: "找不到此筆支出預算。" }
    end
  end

  def destroy_expenditure_budget
    budget = expenditure_scope.find(params[:id])
    if budget.destroy
      redirect_to budgets_path, notice: "已刪除支出預算。"
    else
      redirect_to budgets_path, alert: "無法刪除此筆支出預算。"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: "找不到此筆支出預算。"
  end

  private

  # Slides are saved rows + one trailing blank for new entry; 0-based Embla index matches
  # record position in `records`, or `records.size` for the blank card.
  def carousel_slide_index_for_id(records, raw_id)
    return nil if raw_id.blank?

    id = raw_id.to_i
    return nil if id <= 0

    idx = records.index { |r| r.id == id }
    return nil unless idx

    idx
  end

  def carousel_focus_from_params(revenue_records, expenditure_records)
    exp_ix = carousel_slide_index_for_id(expenditure_records, params[:expenditure_focus])
    rev_ix = carousel_slide_index_for_id(revenue_records, params[:revenue_focus])
    revenue_end = revenue_records.size
    expenditure_end = expenditure_records.size

    if exp_ix
      { kind: :expenditure, revenue_index: revenue_end, expenditure_index: exp_ix }
    elsif rev_ix
      { kind: :revenue, revenue_index: rev_ix, expenditure_index: expenditure_end }
    else
      { kind: :revenue, revenue_index: revenue_end, expenditure_index: expenditure_end }
    end
  end

  def budget_index_state
    user = trial_account_owner
    return [ [], [], nil ] unless user

    today = Time.zone.today
    calendar_month = CalendarMonth.find_or_create_by!(year: today.year, month: today.month)
    revenue_budgets = RevenueBudget.where(calendar_month: calendar_month).order(:id).to_a
    expenditure_budgets = ExpenditureBudget.where(calendar_month: calendar_month).order(:id).to_a
    [ revenue_budgets, expenditure_budgets, calendar_month ]
  end

  def set_budget_context
    @user = trial_account_owner
    unless @user
      redirect_to budgets_path, alert: "無法準備試用環境，請稍後再試。"
      return
    end

    today = Time.zone.today
    @calendar_month = CalendarMonth.find_or_create_by!(year: today.year, month: today.month)
  end

  def revenue_scope
    RevenueBudget.where(calendar_month: @calendar_month, user: @user)
  end

  def expenditure_scope
    ExpenditureBudget.where(calendar_month: @calendar_month, user: @user)
  end

  def revenue_budget_attributes
    raw = params.require(:revenue_budget).permit(:amount, :note, :item)
    {
      item: raw[:item].presence || "收入預算",
      note: raw[:note].presence,
      amount: parse_money(raw[:amount])
    }
  end

  def expenditure_budget_attributes
    raw = params.require(:expenditure_budget).permit(:amount, :note, :category, :item)
    {
      category: raw[:category].presence,
      item: raw[:item].presence,
      note: raw[:note].presence,
      amount: parse_money(raw[:amount])
    }
  end

  def parse_money(value)
    s = value.to_s.strip.delete(",").presence
    return nil if s.blank?

    BigDecimal(s)
  rescue ArgumentError
    nil
  end
end
