# frozen_string_literal: true

class ActualExpendituresController < ApplicationController
  def create
    user = trial_account_owner
    unless user
      return respond_unavailable
    end

    record = ActualExpenditure.new
    apply_expenditure_params(record, user)
    save_record(record, created: true)
  end

  def update
    user = trial_account_owner
    unless user
      return respond_unavailable
    end

    record = find_owned_expenditure(user, params[:id])
    return respond_not_found unless record

    apply_expenditure_params(record, user)
    save_record(record, created: false)
  end

  def destroy
    user = trial_account_owner
    unless user
      return respond_unavailable
    end

    record = find_owned_expenditure(user, params[:id])
    return respond_not_found unless record

    record.destroy!
    respond_to do |format|
      format.json { render json: { ok: true } }
      format.html { redirect_to expense_history_path, notice: "已刪除。" }
    end
  end

  private

  def respond_unavailable
    respond_to do |format|
      format.json { render json: { ok: false, errors: [ "無法準備試用環境。" ] }, status: :service_unavailable }
      format.html { redirect_to root_path, alert: "無法準備試用環境，請稍後再試。" }
    end
  end

  def respond_not_found
    respond_to do |format|
      format.json { render json: { ok: false, errors: [ "找不到紀錄。" ] }, status: :not_found }
      format.html { redirect_to expense_history_path, alert: "找不到紀錄。" }
    end
  end

  def find_owned_expenditure(user, id)
    ActualExpenditure.where(user: user).find_by(id: id)
  end

  def apply_expenditure_params(record, user)
    raw = actual_expenditure_params
    date = parse_date(raw[:transaction_date])
    cm = CalendarMonth.find_or_create_by!(year: date.year, month: date.month)

    record.assign_attributes(
      user: user,
      calendar_month: cm,
      transaction_date: date,
      transaction_item: raw[:transaction_item].to_s.strip,
      category: raw[:category].to_s.strip,
      payment_method: raw[:payment_method].to_s.strip,
      credit_card_payment_method: raw[:credit_card_payment_method].presence,
      payment_timing: raw[:payment_timing].presence,
      payment_platform: raw[:payment_platform].presence,
      actual_amount: parse_money(raw[:actual_amount]),
      posted_amount: parse_money(raw[:posted_amount]),
      note: raw[:note].presence
    )
  end

  def save_record(record, created:)
    if record.save
      today_cm = CalendarMonth.find_or_create_by!(
        year: Time.zone.today.year,
        month: Time.zone.today.month
      )
      in_dashboard_month = record.calendar_month_id == today_cm.id
      respond_to do |format|
        format.json do
          payload = {
            ok: true,
            id: record.id,
            record: history_record_json(record)
          }
          if created
            payload[:row] = (in_dashboard_month ? row_json(record) : nil)
            payload[:month_tally] = month_tally_json(today_cm, record.user)
          end
          render json: payload
        end
        format.html do
          path = created ? root_path : expense_history_path
          redirect_to path, notice: created ? "已儲存實際支出。" : "已更新。"
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: { ok: false, errors: record.errors.full_messages },
                 status: :unprocessable_entity
        end
        format.html do
          path = created ? root_path : expense_history_path
          redirect_to path, alert: record.errors.full_messages.to_sentence.presence || "無法儲存。"
        end
      end
    end
  end

  def actual_expenditure_params
    params.require(:actual_expenditure).permit(
      :transaction_date,
      :transaction_item,
      :category,
      :payment_method,
      :credit_card_payment_method,
      :payment_timing,
      :payment_platform,
      :actual_amount,
      :posted_amount,
      :note
    )
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError, TypeError
    Time.zone.today
  end

  def parse_money(value)
    s = value.to_s.strip.delete(",").presence
    return nil if s.blank?

    BigDecimal(s)
  rescue ArgumentError
    nil
  end

  def row_json(record)
    {
      transaction_date: record.transaction_date.iso8601,
      category: record.category,
      transaction_item: record.transaction_item,
      payment_method: record.payment_method,
      actual_amount: record.actual_amount.to_s("F"),
      posted_amount: record.posted_amount.to_s("F")
    }
  end

  def history_record_json(record)
    {
      id: record.id,
      transaction_date: record.transaction_date.iso8601,
      transaction_item: record.transaction_item,
      category: record.category,
      payment_summary: record.payment_summary,
      payment_method: record.payment_method,
      credit_card_payment_method: record.credit_card_payment_method,
      payment_timing: record.payment_timing,
      payment_platform: record.payment_platform,
      actual_amount: Kernel.format("%.0f", record.actual_amount.to_d.round),
      posted_amount: Kernel.format("%.0f", record.posted_amount.to_d.round),
      note: record.note.to_s
    }
  end

  def month_tally_json(calendar_month, user)
    scope = ActualExpenditure.where(user: user, calendar_month: calendar_month)
    total = scope.sum(:actual_amount)
    by_cat = scope.group(:category).sum(:posted_amount)
    {
      total: total.to_s("F"),
      count: scope.count,
      by_category: by_cat.transform_values { |v| v.to_s("F") }
    }
  end
end
