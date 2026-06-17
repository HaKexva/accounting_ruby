# frozen_string_literal: true

require "test_helper"

class CalendarMonthResolutionTest < ActiveSupport::TestCase
  include CalendarMonthResolution

  def params
    @params ||= {}
  end

  test "calendar_month_choices_for includes only through planning horizon not selected plus one" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      april = CalendarMonth.create!(year: 2026, month: 4)
      july = CalendarMonth.create!(year: 2026, month: 7)
      user = users(:one)

      choices = calendar_month_choices_for(user, selected: april)
      labels = choices.map { |cm| "#{cm.year}-#{cm.month}" }

      assert_includes labels, "2026-5"
      assert_includes labels, "2026-6"
      assert_includes labels, "2026-4"
      refute_includes labels, "2026-7"
    end
  end

  test "calendar_month_from_params clamps ym beyond planning horizon" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      @params = { ym: "2026-08" }
      cm = calendar_month_from_params
      assert_equal 2026, cm.year
      assert_equal 6, cm.month
    end
  end

  test "planning horizon rolls from December to January next year" do
    travel_to Time.zone.local(2026, 12, 10, 12, 0, 0) do
      horizon = planning_horizon_month
      assert_equal 2027, horizon.year
      assert_equal 1, horizon.month

      choices = calendar_month_choices_for(users(:one), selected: horizon)
      labels = choices.map { |cm| "#{cm.year}-#{cm.month}" }
      refute_includes labels, "2027-2"
    end
  end
end
