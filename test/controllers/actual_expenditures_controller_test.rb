# frozen_string_literal: true

require "test_helper"

class ActualExpendituresControllerTest < ActionDispatch::IntegrationTest
  test "create returns json with row when in current dashboard month" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      assert_difference -> { ActualExpenditure.count }, 1 do
        post actual_expenditures_path,
             params: {
               actual_expenditure: {
                 transaction_date: "2026-05-10",
                 transaction_item: "午餐",
                 category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
                 payment_method: "現金",
                 actual_amount: "120",
                 posted_amount: "120",
                 note: ""
               }
             },
             as: :json,
             headers: { "Accept" => "application/json" }
      end
      assert_response :success
      json = JSON.parse(response.body)
      assert json["ok"]
      assert json["row"]
      assert_equal "午餐", json["row"]["transaction_item"]
      assert json["month_tally"]["by_category"].is_a?(Hash)
    end
  end

  test "create returns row when expense month matches dashboard ym param" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      assert_difference -> { ActualExpenditure.count }, 1 do
        post actual_expenditures_path,
             params: {
               ym: "2026-04",
               actual_expenditure: {
                 transaction_date: "2026-04-01",
                 transaction_item: "四月項目",
                 category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
                 payment_method: "現金",
                 actual_amount: "50",
                 posted_amount: "50",
                 note: ""
               }
             },
             as: :json,
             headers: { "Accept" => "application/json" }
      end
      assert_response :success
      json = JSON.parse(response.body)
      assert json["ok"]
      assert json["row"]
      assert json["month_tally"]["by_category"].is_a?(Hash)
    end
  end

  test "create omits row json when accounting month is not current wall month" do
    travel_to Time.zone.local(2026, 5, 15, 12, 0, 0) do
      assert_difference -> { ActualExpenditure.count }, 1 do
        post actual_expenditures_path,
             params: {
               actual_expenditure: {
                 transaction_date: "2026-04-01",
                 transaction_item: "舊月",
                 category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
                 payment_method: "現金",
                 actual_amount: "50",
                 posted_amount: "50",
                 note: ""
               }
             },
             as: :json,
             headers: { "Accept" => "application/json" }
      end
      assert_response :success
      json = JSON.parse(response.body)
      assert json["ok"]
      assert_nil json["row"]
    end
  end

  test "update returns json with record" do
    expenditure = actual_expenditures(:one)
    patch actual_expenditure_path(expenditure),
          params: {
            actual_expenditure: {
              transaction_date: expenditure.transaction_date.iso8601,
              transaction_item: "更新項目",
              category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
              payment_method: "現金",
              actual_amount: "200",
              posted_amount: "200",
              note: "備註"
            }
          },
          as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal "更新項目", json["record"]["transaction_item"]
    assert_equal "更新項目", expenditure.reload.transaction_item
  end

  test "destroy removes record" do
    expenditure = actual_expenditures(:two)
    assert_difference -> { ActualExpenditure.count }, -1 do
      delete "/actual_expenditures/#{expenditure.id}", as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
  end

  test "update returns not found for missing id" do
    patch actual_expenditure_path(99_999),
          params: {
            actual_expenditure: {
              transaction_date: "2026-04-25",
              transaction_item: "x",
              category: ExpenditureTaxonomy::DEFAULT_CATEGORIES.first,
              payment_method: "現金",
              actual_amount: "10",
              posted_amount: "10"
            }
          },
          as: :json
    assert_response :not_found
  end
end
