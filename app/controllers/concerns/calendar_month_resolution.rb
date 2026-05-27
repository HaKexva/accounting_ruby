# frozen_string_literal: true

module CalendarMonthResolution
  extend ActiveSupport::Concern

  YM_PARAM = /\A(\d{4})-(\d{1,2})\z/

  private

  def ym_query_params
    params[:ym].present? ? { ym: params[:ym] } : {}
  end

  def optional_calendar_month_from_params
    return nil if params[:ym].blank?

    calendar_month_from_params
  end

  def calendar_month_from_params(default_date: Time.zone.today)
    parsed = parse_ym_param(params[:ym])
    parsed ||= parse_year_month_params(params[:year], params[:month])
    if parsed
      year, month = parsed
      if month.between?(1, 12) && within_planning_horizon?(year, month, reference_date: default_date)
        return CalendarMonth.for_year_month!(year, month)
      elsif month.between?(1, 12)
        horizon = planning_horizon_month(reference_date: default_date)
        return horizon
      end
    end

    CalendarMonth.for_year_month!(default_date.year, default_date.month)
  end

  def calendar_month_choices_for(user, selected:)
    today = Time.zone.today
    current = CalendarMonth.for_year_month!(today.year, today.month)
    horizon = planning_horizon_month(reference_date: today)
    selected ||= current
    selected = horizon if month_after?(selected, horizon)

    anchor_months = [ current, horizon, selected ].uniq

    months =
      if user
        ids = anchor_months.map(&:id)
        ids.concat(ActualExpenditure.where(user: user).distinct.pluck(:calendar_month_id))
        ids.concat(ExpenditureBudget.where(user: user).distinct.pluck(:calendar_month_id))
        ids.concat(RevenueBudget.where(user: user).distinct.pluck(:calendar_month_id))

        CalendarMonth.where(id: ids.compact.uniq).order(year: :desc, month: :desc).to_a
      else
        anchor_months
      end

    months.reject { |cm| month_after?(cm, horizon) }
  end

  def planning_horizon_month(reference_date: Time.zone.today)
    CalendarMonth.planning_horizon_month(reference_date: reference_date)
  end

  def within_planning_horizon?(year, month, reference_date: Time.zone.today)
    CalendarMonth.on_or_before_planning_horizon?(year, month, reference_date: reference_date)
  end

  def month_after?(calendar_month, horizon)
    calendar_month.year > horizon.year ||
      (calendar_month.year == horizon.year && calendar_month.month > horizon.month)
  end

  def calendar_month_ym(calendar_month)
    Kernel.format("%04d-%02d", calendar_month.year, calendar_month.month)
  end

  def parse_ym_param(raw)
    match = raw.to_s.strip.match(YM_PARAM)
    return nil unless match

    [ match[1].to_i, match[2].to_i ]
  end

  def parse_year_month_params(year_raw, month_raw)
    year = year_raw.presence&.to_i
    month = month_raw.presence&.to_i
    return nil unless year && month

    [ year, month ]
  end
end
