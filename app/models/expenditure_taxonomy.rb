# frozen_string_literal: true

# Reference lists for 實際支出登錄（消費類別、支付相關欄位）.
class ExpenditureTaxonomy
  CATEGORIES = [
    "生活花費：食",
    "生活花費：帳單",
    "生活花費：衣與外貌",
    "生活花費：住、居家裝修、衛生用品、次月繳納帳單",
    "生活花費：行",
    "生活花費：育",
    "生活花費：樂",
    "生活花費：健（醫療）",
    "儲蓄",
    "家人：過年紅包、紀念日"
  ].freeze

  PAYMENT_METHODS = [
    "現金",
    "多元支付",
    "玉山轉帳",
    "Linebank轉帳",
    "玉山信用卡",
    "富邦信用卡"
  ].freeze

  CREDIT_CARD_PAYMENT_KINDS = [
    "分期付款",
    "一次支付"
  ].freeze

  PAYMENT_TIMINGS = [
    "本月支付",
    "次月支付"
  ].freeze

  PAYMENT_PLATFORMS = [
    "LINE Pay",
    "LINE Bank",
    "悠遊付",
    "髮果",
    "MOS card",
    "星巴克隨行卡"
  ].freeze
end
