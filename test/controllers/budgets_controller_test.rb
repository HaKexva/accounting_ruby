# frozen_string_literal: true

require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get budgets_path
    assert_response :success
  end

  test "index includes next month in selector for early budget entry" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      get budgets_path
      assert_response :success
      assert_includes response.body, 'value="2026-06"'
      assert_includes response.body, "2026 年 6 月（下月）"
      assert_includes response.body, "可選"
      assert CalendarMonth.exists?(year: 2026, month: 6)
    end
  end

  test "index includes month selector and ym loads selected month" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      april = CalendarMonth.create!(year: 2026, month: 4)
      RevenueBudget.create!(
        user: users(:one),
        calendar_month: april,
        item: "四月薪水",
        amount: 1
      )

      get budgets_path(ym: "2026-04")
      assert_response :success
      assert_includes response.body, "calendar-month-select"
      assert_includes response.body, "budget_summary_calendar_month"
      assert_includes response.body, "四月薪水"
      assert_includes response.body, "2026 年 4 月摘要"
      assert_includes response.body, 'value="2026-04"'
    end
  end

  test "index shows only the current user budgets" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      month = CalendarMonth.find_or_create_by!(year: 2026, month: 5)
      other = User.create!(google_uid: "other-budget-user", email: "other-budget@test.example")

      mine = RevenueBudget.create!(
        user: users(:one),
        calendar_month: month,
        item: "我的薪水",
        amount: 100
      )
      RevenueBudget.create!(
        user: other,
        calendar_month: month,
        item: "別人的薪水",
        amount: 999
      )

      get budgets_path
      assert_response :success
      assert_includes response.body, mine.item
      assert_not_includes response.body, "別人的薪水"
    end
  end

  test "create revenue budget" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      assert_difference -> { RevenueBudget.count }, 1 do
        post budget_revenue_budgets_path, params: {
          ym: "2026-05",
          revenue_budget: { amount: "1000.50", note: "bonus", item: "薪水" }
        }
      end
      assert_redirected_to budgets_path(ym: "2026-05")
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
