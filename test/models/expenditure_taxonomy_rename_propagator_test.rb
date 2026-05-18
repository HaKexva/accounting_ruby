# frozen_string_literal: true

require "test_helper"

class ExpenditureTaxonomyRenamePropagatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @current_month = CalendarMonth.find_or_create_by!(
      year: Time.zone.today.year,
      month: Time.zone.today.month
    )
    @other_month = calendar_months(:one)
    if @other_month.id == @current_month.id
      @other_month = CalendarMonth.create!(year: @current_month.year - 1, month: @current_month.month)
    end

    ExpenditureTaxonomy.ensure_seeded!(@user)
    @category_item = @user.expenditure_taxonomy_items.for_kind("category").first
    @old_name = @category_item.name
    @new_name = "#{@old_name}（已更名）"

    @expense_current = ActualExpenditure.create!(
      user: @user,
      calendar_month: @current_month,
      transaction_date: Time.zone.today,
      transaction_item: "午餐",
      category: @old_name,
      payment_method: "現金",
      actual_amount: 100,
      posted_amount: 100
    )

    @expense_history_month = ActualExpenditure.create!(
      user: @user,
      calendar_month: @other_month,
      transaction_date: Date.new(@other_month.year, @other_month.month, 1),
      transaction_item: "歷史午餐",
      category: @old_name,
      payment_method: "現金",
      actual_amount: 50,
      posted_amount: 50
    )

    @budget_current = ExpenditureBudget.create!(
      user: @user,
      calendar_month: @current_month,
      category: @old_name,
      item: "預算列",
      amount: 1000
    )
  end

  test "renames category on all expenditures and budgets for user" do
    count = ExpenditureTaxonomyRenamePropagator.call(
      user: @user,
      kind: "category",
      from: @old_name,
      to: @new_name
    )

    assert_equal 3, count
    assert_equal @new_name, @expense_current.reload.category
    assert_equal @new_name, @expense_history_month.reload.category
    assert_equal @new_name, @budget_current.reload.category
  end

  test "does not rename other users rows" do
    other = User.create!(google_uid: "other-rename", email: "other-rename@test.example")
    other_expense = ActualExpenditure.create!(
      user: other,
      calendar_month: @current_month,
      transaction_date: Time.zone.today,
      transaction_item: "他人",
      category: @old_name,
      payment_method: "現金",
      actual_amount: 10,
      posted_amount: 10
    )

    ExpenditureTaxonomyRenamePropagator.call(
      user: @user,
      kind: "category",
      from: @old_name,
      to: @new_name
    )

    assert_equal @old_name, other_expense.reload.category
  end
end
