# frozen_string_literal: true

require "test_helper"

class CalendarMonthResolutionTest < ActiveSupport::TestCase
  include CalendarMonthResolution

  def params
    {}
  end

  test "calendar_month_choices_for always includes next month after today and after selected" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      april = CalendarMonth.create!(year: 2026, month: 4)
      user = users(:one)

      choices = calendar_month_choices_for(user, selected: april)
      labels = choices.map { |cm| "#{cm.year}-#{cm.month}" }

      assert_includes labels, "2026-5"
      assert_includes labels, "2026-6"
      assert_includes labels, "2026-4"
    end
  end
end
