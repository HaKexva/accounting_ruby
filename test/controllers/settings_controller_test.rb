# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    ExpenditureTaxonomyItem.where(user: @user).delete_all
    ExpenditureTaxonomy.ensure_seeded!(@user)
  end

  test "index shows taxonomy manager" do
    get settings_path
    assert_response :success
    assert_includes response.body, "settings-taxonomy-kind"
    assert_includes response.body, "消費類別"
    assert_includes response.body, ExpenditureTaxonomy::DEFAULT_CATEGORIES.first
  end

  test "create taxonomy item" do
    assert_difference -> { @user.expenditure_taxonomy_items.where(kind: "category").count }, 1 do
      post settings_taxonomy_items_path, params: {
        expenditure_taxonomy_item: { kind: "category", name: "測試類別" }
      }
    end
    assert_redirected_to settings_path(kind: "category")
    assert_equal "測試類別", @user.expenditure_taxonomy_items.find_by(name: "測試類別").name
  end

  test "update taxonomy item" do
    item = @user.expenditure_taxonomy_items.for_kind("category").first
    patch settings_taxonomy_item_path(item), params: {
      expenditure_taxonomy_item: { name: "更新後類別" }
    }
    assert_redirected_to settings_path(kind: "category")
    assert_equal "更新後類別", item.reload.name
  end

  test "update taxonomy item renames expenditures including history" do
    month = CalendarMonth.find_or_create_by!(
      year: Time.zone.today.year,
      month: Time.zone.today.month
    )
    past_month = CalendarMonth.create!(year: month.year - 1, month: month.month)
    item = @user.expenditure_taxonomy_items.for_kind("category").first
    old_name = item.name

    expense = ActualExpenditure.create!(
      user: @user,
      calendar_month: past_month,
      transaction_date: Date.new(past_month.year, past_month.month, 1),
      transaction_item: "舊紀錄",
      category: old_name,
      payment_method: "現金",
      actual_amount: 10,
      posted_amount: 10
    )

    patch settings_taxonomy_item_path(item), params: {
      expenditure_taxonomy_item: { name: "歷史同步類別" }
    }

    assert_redirected_to settings_path(kind: "category")
    assert_equal "歷史同步類別", expense.reload.category

    get expense_history_path
    assert_response :success
    assert_includes response.body, "歷史同步類別"
    assert_includes response.body, "舊紀錄"
  end

  test "destroy taxonomy item" do
    item = @user.expenditure_taxonomy_items.for_kind("payment_platform").first
    assert_difference -> { @user.expenditure_taxonomy_items.count }, -1 do
      delete delete_settings_taxonomy_item_path(item)
    end
    assert_redirected_to settings_path(kind: "payment_platform")
  end
end
