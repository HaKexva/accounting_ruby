# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get root_path
    assert_response :success
  end

  test "index pins 實際支出 page title at top while scrolling" do
    get root_path
    assert_response :success
    assert_equal 1, response.body.scan(/<h1[^>]*>實際支出<\/h1>/).size
    assert_includes response.body, "sticky top-0 z-20"
    assert_not_includes response.body, "shrink-0 lg:hidden"
  end

  test "index includes live category summary" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      get root_path
      assert_response :success
      assert_includes response.body, "expenditure-live-category-summary"
      assert_includes response.body, "data-expenditure-live-category-summary-budgets-value"
      assert_match(
        /data-expenditure-live-category-summary-target="budgetAmount"/,
        response.body
      )
      assert_operator response.body.scan(/data-expenditure-live-category-summary-target="budgetAmount"/).size, :>=, 2
      assert_includes response.body, "預算"
      assert_includes response.body, "餘額"
      assert_includes response.body, "lg:grid-cols-3"
      assert_includes response.body, "類別統計"
      assert_includes response.body, "總預算"
      assert_includes response.body, "總支出"
      assert_includes response.body, 'data-actual-expenditure-form-target="monthTotal"'
      assert_includes response.body, "data-actual-expenditure-form-month-total-base-value"
      assert_includes response.body, 'data-expenditure-mobile-sticky-summary-target="summaryHeader"'
      assert_includes response.body, "flex-nowrap"
      assert_includes response.body, "input->expenditure-live-category-summary#recalc"
      assert_includes response.body, "change->expenditure-live-category-summary#recalc"
      assert_includes response.body, "actual_expenditure_actual_amount"
      assert_includes response.body, "actual_expenditure_posted_amount"
      assert_includes response.body, "actual_expenditure_category"
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

  test "history supports text search filter" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      cm = CalendarMonth.for_year_month!(2026, 5)
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: cm,
        transaction_date: Date.new(2026, 5, 10),
        transaction_item: "晚餐",
        category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
        payment_method: "現金",
        actual_amount: 100,
        posted_amount: 100,
        note: "公司聚餐"
      )
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: cm,
        transaction_date: Date.new(2026, 5, 11),
        transaction_item: "早餐",
        category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
        payment_method: "現金",
        actual_amount: 50,
        posted_amount: 50,
        note: "普通"
      )

      get expense_history_path(q: "聚餐")
      assert_response :success
      assert_includes response.body, "晚餐"
      assert_not_includes response.body, "早餐"
    end
  end

  test "history supports structured filters" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      cm = CalendarMonth.for_year_month!(2026, 5)
      cat_a, cat_b = ExpenditureTaxonomy::DEFAULT_CATEGORIES.first(2)
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: cm,
        transaction_date: Date.new(2026, 5, 1),
        transaction_item: "FILTER_MATCH_A",
        category: cat_a,
        payment_method: "多元支付",
        payment_platform: ExpenditureTaxonomy::DEFAULT_PAYMENT_PLATFORMS.first,
        actual_amount: 100,
        posted_amount: 120
      )
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: cm,
        transaction_date: Date.new(2026, 5, 20),
        transaction_item: "FILTER_OUT_B",
        category: cat_b,
        payment_method: "現金",
        actual_amount: 10,
        posted_amount: 10
      )

      get expense_history_path(
        category: cat_a,
        payment_method: "多元支付",
        date_from: "2026-05-01",
        date_to: "2026-05-10",
        min_posted_amount: "100",
        max_posted_amount: "200"
      )
      assert_response :success
      assert_includes response.body, "FILTER_MATCH_A"
      assert_not_includes response.body, "FILTER_OUT_B"
    end
  end

  test "history supports amount sort" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      cm = CalendarMonth.for_year_month!(2026, 5)
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: cm,
        transaction_date: Date.new(2026, 5, 1),
        transaction_item: "SORT_LOW",
        category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
        payment_method: "現金",
        actual_amount: 10,
        posted_amount: 10
      )
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: cm,
        transaction_date: Date.new(2026, 5, 2),
        transaction_item: "SORT_HIGH",
        category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
        payment_method: "現金",
        actual_amount: 500,
        posted_amount: 500
      )

      get expense_history_path(sort: "amount_desc")
      assert_response :success
      assert_operator response.body.index("SORT_HIGH"), :<, response.body.index("SORT_LOW")
    end
  end

  test "history shows payment summary chips" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      cm = CalendarMonth.for_year_month!(2026, 5)
      ActualExpenditure.create!(
        user: users(:one),
        calendar_month: cm,
        transaction_date: Date.new(2026, 5, 3),
        transaction_item: "PAYMENT_CHIP_ROW",
        category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
        payment_method: "多元支付",
        payment_platform: ExpenditureTaxonomy::DEFAULT_PAYMENT_PLATFORMS.first,
        actual_amount: 80,
        posted_amount: 80
      )

      get expense_history_path
      assert_response :success
      assert_includes response.body, "多元支付 · #{ExpenditureTaxonomy::DEFAULT_PAYMENT_PLATFORMS.first}"
      assert_includes response.body, 'name="sort"'
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
