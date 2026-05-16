# frozen_string_literal: true

require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get budgets_path
    assert_response :success
  end

  test "create revenue budget" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      assert_difference -> { RevenueBudget.count }, 1 do
        post budget_revenue_budgets_path, params: {
          revenue_budget: { amount: "1000.50", note: "bonus", item: "薪水" }
        }
      end
      assert_redirected_to budgets_path
      assert_equal "已儲存收入預算。", flash[:notice]
      created = RevenueBudget.order(:id).last
      assert_equal BigDecimal("1000.5"), created.amount
      assert_equal "bonus", created.note
      assert_equal "薪水", created.item
    end
  end

  test "update revenue budget" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      rev = revenue_budgets(:one)
      patch budget_revenue_budget_path(rev), params: {
        revenue_budget: { amount: "2500.00", note: "rev", item: rev.item }
      }
      assert_redirected_to budgets_path
      assert_equal "已更新收入預算。", flash[:notice]
      assert_equal BigDecimal("2500"), rev.reload.amount
      assert_equal "rev", rev.note
    end
  end

  test "create expenditure budget" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      assert_difference -> { ExpenditureBudget.count }, 1 do
        post budget_expenditure_budgets_path, params: {
          expenditure_budget: {
            amount: "500",
            note: "groceries",
            category: "生活花費：食",
            item: "午餐"
          }
        }
      end
      assert_redirected_to budgets_path
      created = ExpenditureBudget.order(:id).last
      assert_equal BigDecimal("500"), created.amount
      assert_equal "生活花費：食", created.category
    end
  end

  test "update expenditure budget" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      exp = expenditure_budgets(:one)
      patch budget_expenditure_budget_path(exp), params: {
        expenditure_budget: {
          amount: "888.25",
          note: "n",
          category: "儲蓄",
          item: exp.item
        }
      }
      assert_redirected_to budgets_path
      exp.reload
      assert_equal BigDecimal("888.25"), exp.amount
      assert_equal "儲蓄", exp.category
    end
  end
end
