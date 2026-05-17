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
      assert_includes response.body, "尚未使用的預算支出"
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
  end
end
