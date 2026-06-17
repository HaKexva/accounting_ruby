require "test_helper"

class ActualExpenditureTest < ActiveSupport::TestCase
  test "credit card payment method required when payment uses credit card" do
    record = actual_expenditures(:one)
    record.payment_method = "玉山信用卡"
    record.credit_card_payment_method = nil
    record.payment_timing = "本月支付"

    assert_not record.valid?
    assert_includes record.errors[:credit_card_payment_method], "can't be blank"
  end

  test "credit card payment method not required for cash" do
    record = actual_expenditures(:one)
    record.payment_method = "現金"
    record.credit_card_payment_method = nil
    record.payment_timing = nil

    assert record.valid?
  end

  test "payment platform required when payment method is multi-pay" do
    record = actual_expenditures(:one)
    record.payment_method = "多元支付"
    record.payment_platform = nil

    assert_not record.valid?
    assert_includes record.errors[:payment_platform], "can't be blank"
  end

  test "payment platform not required for cash" do
    record = actual_expenditures(:one)
    record.payment_method = "現金"
    record.payment_platform = nil

    assert record.valid?
  end

  test "payment_summary joins method and platform for multi-pay" do
    record = actual_expenditures(:one)
    record.assign_attributes(
      payment_method: "多元支付",
      payment_platform: "LINE Pay",
      credit_card_payment_method: nil,
      payment_timing: nil
    )
    assert_equal "多元支付 · LINE Pay", record.payment_summary
  end

  test "payment_summary joins method card kind and timing for credit card" do
    record = actual_expenditures(:two)
    record.assign_attributes(
      payment_method: "玉山信用卡",
      credit_card_payment_method: "一次支付",
      payment_timing: "本月支付",
      payment_platform: nil
    )
    assert_equal "玉山信用卡 · 一次支付 · 本月支付", record.payment_summary
  end
end
