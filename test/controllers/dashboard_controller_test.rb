# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get root_path
    assert_response :success
  end

  test "index includes live category summary" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      get root_path
      assert_response :success
      assert_includes response.body, "expenditure-live-category-summary"
      assert_includes response.body, "data-expenditure-live-category-summary-budgets-value"
      assert_includes response.body, "預算"
      assert_includes response.body, "餘額"
      assert_includes response.body, "lg:grid-cols-3"
      assert_includes response.body, "類別統計"
      assert_includes response.body, "總預算"
      assert_includes response.body, "總支出"
      assert_includes response.body, 'data-actual-expenditure-form-target="monthTotal"'
      assert_includes response.body, 'data-expenditure-mobile-sticky-summary-target="summaryHeader"'
      assert_includes response.body, "flex-nowrap"
    end
  end

  test "index includes month selector with ym navigation" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      get root_path
      assert_response :success
      assert_includes response.body, "calendar-month-select"
      assert_includes response.body, 'value="2026-05"'
    end
  end

  test "index with ym shows selected month summary data" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      april = CalendarMonth.create!(year: 2026, month: 4)
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: april,
        transaction_date: Date.new(2026, 4, 10),
        transaction_item: "四月午餐",
        category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
        payment_method: "現金",
        actual_amount: 100,
        posted_amount: 100
      )

      get root_path(ym: "2026-04")
      assert_response :success
      assert_includes response.body, "2026 年 4 月"
      assert_includes response.body, 'value="2026-04"'
      assert_includes response.body, 'name="ym" value="2026-04"'
    end
  end

  test "index includes consumption structure chart data" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      get root_path
      assert_response :success
      assert_includes response.body, "本月消費支出結構"
      assert_includes response.body, "預算收入－預算支出"
      assert_includes response.body, "尚未使用預算"
      assert_includes response.body, "data-expenditure-month-chart-budgets-value"
      assert_includes response.body, "data-expenditure-month-chart-revenue-total-value"
      assert_includes response.body, "data-expenditure-month-chart-category-order-value"
    end
  end

  test "history includes month filter" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      get expense_history_path
      assert_response :success
      assert_includes response.body, "calendar-month-select"
      assert_includes response.body, "全部月份"
    end
  end

  test "history with ym filters expenditures" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      april = CalendarMonth.create!(year: 2026, month: 4)
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: april,
        transaction_date: Date.new(2026, 4, 10),
        transaction_item: "四月午餐",
        category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
        payment_method: "現金",
        actual_amount: 100,
        posted_amount: 100
      )

      get expense_history_path(ym: "2026-04")
      assert_response :success
      assert_includes response.body, "四月午餐"
      assert_includes response.body, "2026 年 4 月紀錄"
    end
  end

  test "history with ym and no matching records still shows month filter" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      get expense_history_path(ym: "2026-03")
      assert_response :success
      assert_includes response.body, "history_calendar_month"
      assert_includes response.body, "calendar-month-select"
      assert_includes response.body, "此月份尚無紀錄"
      assert_includes response.body, "2026 年 3 月紀錄"
    end
  end

  test "history includes edit and delete controls" do
    get expense_history_path
    assert_response :success
    assert_includes response.body, "expenditure-history"
    assert_includes response.body, "刪除"
    assert_includes response.body, "編輯"
    assert_includes response.body, "編輯支出"
      assert_includes response.body, 'data-expenditure-history-action="open-edit"'
      assert_includes response.body, 'data-expenditure-history-action="destroy"'
    assert_match(%r{data-expenditure-history-record-param="[A-Za-z0-9+/=]+"}, response.body)
    assert_includes response.body, "data-expenditure-id="
    assert_includes response.body, 'id="history_edit_category"'
    assert_includes response.body, 'id="history_edit_payment_method"'
    assert_includes response.body, 'id="history_edit_credit_card_payment_method"'
  end
end
