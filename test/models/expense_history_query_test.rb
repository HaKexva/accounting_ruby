# frozen_string_literal: true

require "test_helper"

class ExpenseHistoryQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @scope = ActualExpenditure.where(user: @user)
    @taxonomy = ExpenditureTaxonomy.for_user(@user)
  end

  test "filters by category" do
    filters = ExpenseHistoryQuery::Filters.from_params(
      { category: "生活花費：食" },
      taxonomy: @taxonomy
    )
    rows = ExpenseHistoryQuery.new(scope: @scope, filters: filters).call

    assert_equal [ actual_expenditures(:one).id ], rows.pluck(:id)
  end

  test "filters by payment method" do
    filters = ExpenseHistoryQuery::Filters.from_params(
      { payment_method: "多元支付" },
      taxonomy: @taxonomy
    )
    rows = ExpenseHistoryQuery.new(scope: @scope, filters: filters).call

    assert_equal [ actual_expenditures(:one).id ], rows.pluck(:id)
  end

  test "ignores category not in taxonomy" do
    filters = ExpenseHistoryQuery::Filters.from_params(
      { category: "not-a-real-category" },
      taxonomy: @taxonomy
    )

    assert_nil filters.category
    assert_equal 2, ExpenseHistoryQuery.new(scope: @scope, filters: filters).call.count
  end

  test "sorts by amount descending" do
    one = actual_expenditures(:one)
    two = actual_expenditures(:two)
    one.update!(posted_amount: 100)
    two.update!(posted_amount: 50)

    filters = ExpenseHistoryQuery::Filters.from_params({ sort: "amount_desc" }, taxonomy: @taxonomy)
    rows = ExpenseHistoryQuery.new(scope: @scope, filters: filters).call

    assert_equal [ one.id, two.id ], rows.pluck(:id)
  end

  test "filters by item keyword" do
    filters = ExpenseHistoryQuery::Filters.from_params({ q: "Lunch" }, taxonomy: @taxonomy)
    rows = ExpenseHistoryQuery.new(scope: @scope, filters: filters).call

    assert_equal [ actual_expenditures(:one).id ], rows.pluck(:id)
  end
end
