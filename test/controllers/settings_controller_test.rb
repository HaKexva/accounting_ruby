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
    assert_includes response.body, "click->settings-taxonomy-kind#sync"
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

  test "update taxonomy item renames current month expenditure and budget rows" do
    month = CalendarMonth.find_or_create_by!(
      year: Time.zone.today.year,
      month: Time.zone.today.month
    )
    item = @user.expenditure_taxonomy_items.for_kind("category").first
    old_name = item.name

    expense = ActualExpenditure.create!(
      user: @user,
      calendar_month: month,
      transaction_date: Time.zone.today,
      transaction_item: "測試",
      category: old_name,
      payment_method: "現金",
      actual_amount: 10,
      posted_amount: 10
    )
    budget = ExpenditureBudget.create!(
      user: @user,
      calendar_month: month,
      category: old_name,
      item: "列",
      amount: 100
    )

    patch settings_taxonomy_item_path(item), params: {
      expenditure_taxonomy_item: { name: "同步後類別" }
    }

    assert_redirected_to settings_path(kind: "category")
    assert_equal "同步後類別", expense.reload.category
    assert_equal "同步後類別", budget.reload.category
  end

  test "update payment method platform flag" do
    item = @user.expenditure_taxonomy_items.for_kind("payment_method").find_by!(name: "多元支付")
    assert item.requires_payment_platform?

    patch settings_taxonomy_item_path(item), params: {
      expenditure_taxonomy_item: { name: "多元支付", requires_payment_platform: "0" }
    }
    assert_redirected_to settings_path(kind: "payment_method")
    assert_not item.reload.requires_payment_platform?
  end

  test "renamed payment method keeps platform link" do
    item = @user.expenditure_taxonomy_items.for_kind("payment_method").find_by!(name: "多元支付")
    patch settings_taxonomy_item_path(item), params: {
      expenditure_taxonomy_item: { name: "行動支付", requires_payment_platform: "1" }
    }
    assert_redirected_to settings_path(kind: "payment_method")
    assert item.reload.requires_payment_platform?
    assert_equal "行動支付", item.name

    month = CalendarMonth.find_or_create_by!(
      year: Time.zone.today.year,
      month: Time.zone.today.month
    )
    record = ActualExpenditure.create!(
      user: @user,
      calendar_month: month,
      transaction_date: Time.zone.today,
      transaction_item: "測試",
      category: @user.expenditure_taxonomy_items.for_kind("category").first.name,
      payment_method: "行動支付",
      payment_platform: "LINE Pay",
      actual_amount: 10,
      posted_amount: 10
    )
    assert record.valid?
    assert_equal "行動支付 · LINE Pay", record.payment_summary
  end

  test "custom payment method can require platform" do
    post settings_taxonomy_items_path, params: {
      expenditure_taxonomy_item: {
        kind: "payment_method",
        name: "自訂電子支付",
        requires_payment_platform: "1"
      }
    }
    assert_redirected_to settings_path(kind: "payment_method")

    month = CalendarMonth.find_or_create_by!(
      year: Time.zone.today.year,
      month: Time.zone.today.month
    )
    record = ActualExpenditure.new(
      user: @user,
      calendar_month: month,
      transaction_date: Time.zone.today,
      transaction_item: "測試",
      category: @user.expenditure_taxonomy_items.for_kind("category").first.name,
      payment_method: "自訂電子支付",
      payment_platform: nil,
      actual_amount: 10,
      posted_amount: 10
    )
    assert_not record.valid?
    assert_includes record.errors[:payment_platform], "can't be blank"
  end

  test "destroy taxonomy item" do
    item = @user.expenditure_taxonomy_items.for_kind("payment_platform").first
    assert_difference -> { @user.expenditure_taxonomy_items.count }, -1 do
      delete delete_settings_taxonomy_item_path(item)
    end
    assert_redirected_to settings_path(kind: "payment_platform")
  end
end
