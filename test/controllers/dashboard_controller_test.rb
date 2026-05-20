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
    assert_includes response.body, "多元支付 · LINE Pay"
    assert_includes response.body, "玉山信用卡 · 一次支付 · 本月支付"
    assert_includes response.body, "篩選與排序"
    assert_includes response.body, 'id="history_filter_sort"'
  end

  test "history shows filter controls when records exist" do
    get expense_history_path
    assert_includes response.body, 'id="history_filter_category"'
    assert_includes response.body, 'id="history_filter_payment_method"'
    assert_includes response.body, 'id="history_filter_month"'
  end

  test "history filters by category" do
    get expense_history_path, params: { category: "生活花費：食" }
    assert_response :success
    assert_select "[data-expenditure-id]", count: 1
    assert_includes response.body, "Lunch"
  end

  test "history shows empty message when filters match nothing" do
    get expense_history_path, params: { category: "生活花費：食", q: "no-such-item" }
    assert_response :success
    assert_includes response.body, "沒有符合條件的紀錄"
    assert_select "[data-expenditure-id]", count: 0
  end

  test "history sorts by amount descending" do
    one = actual_expenditures(:one)
    two = actual_expenditures(:two)
    one.update!(posted_amount: 200)
    two.update!(posted_amount: 10)

    get expense_history_path, params: { sort: "amount_desc" }
    assert_response :success
    assert_operator response.body.index("Lunch"), :<, response.body.index("Transit")
  end
end
