# frozen_string_literal: true

require "test_helper"

class CalendarMonthTest < ActiveSupport::TestCase
  test "following_year_month rolls into January" do
    assert_equal [ 2027, 1 ], CalendarMonth.following_year_month(2026, 12)
    assert_equal [ 2026, 6 ], CalendarMonth.following_year_month(2026, 5)
  end

  test "ensure_next_month_exists creates the next calendar month row" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      june = nil
      assert_difference -> { CalendarMonth.count }, 1 do
        june = CalendarMonth.ensure_next_month_exists!
        assert_equal 2026, june.year
        assert_equal 6, june.month
      end

      assert_no_difference -> { CalendarMonth.count } do
        again = CalendarMonth.ensure_next_month_exists!
        assert_equal june, again
      end
    end
  end

  test "ensure_next_month_exists handles December to January" do
    travel_to Time.zone.local(2026, 12, 10, 12, 0, 0) do
      january = CalendarMonth.ensure_next_month_exists!
      assert_equal 2027, january.year
      assert_equal 1, january.month
    end
  end

  test "on_or_before_planning_horizon rejects months after today plus one" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      assert CalendarMonth.on_or_before_planning_horizon?(2026, 6)
      refute CalendarMonth.on_or_before_planning_horizon?(2026, 7)
    end
  end

  test "on_or_before_planning_horizon allows January after December" do
    travel_to Time.zone.local(2026, 12, 10, 12, 0, 0) do
      assert CalendarMonth.on_or_before_planning_horizon?(2027, 1)
      refute CalendarMonth.on_or_before_planning_horizon?(2027, 2)
    end
  end
end
