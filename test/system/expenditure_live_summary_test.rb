# frozen_string_literal: true

require "application_system_test_case"

class ExpenditureLiveSummaryTest < ApplicationSystemTestCase
  setup do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0)
    @user = users(:one)
    @month = calendar_months(:one)
    ExpenditureBudget.find_or_create_by!(
      user: @user,
      calendar_month: @month,
      category: "生活花費：食"
    ) do |b|
      b.item = "伙食"
      b.amount = 19_259
    end
  end

  test "selecting category updates budget expense remain chips" do
    visit root_path

    find("#actual_expenditure_category").select("生活花費：食")

    assert_selector(
      "[data-expenditure-live-category-summary-target='budgetAmount']",
      text: "NT$19,259",
      wait: 5
    )

    fill_in "actual_expenditure[posted_amount]", with: "100"

    assert_selector(
      "[data-expenditure-live-category-summary-target='expenseAmount']",
      text: "NT$100",
      wait: 5
    )
    assert_selector(
      "[data-expenditure-live-category-summary-target='remainAmount']",
      text: "NT$19,159",
      wait: 5
    )
  end
end
