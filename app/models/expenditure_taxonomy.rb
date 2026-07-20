# frozen_string_literal: true

# Per-user lists for 實際支出登錄（消費類別、支付方式、支付平台）.
# Credit-card sub-fields remain fixed reference lists below.
class ExpenditureTaxonomy
  DEFAULT_CATEGORIES = [
    "飲食",
    "交通",
    "居住",
    "購物",
    "娛樂",
    "醫療",
    "教育",
    "儲蓄",
    "其他"
  ].freeze

  DEFAULT_PAYMENT_METHODS = [
    "現金",
    "行動支付",
    "銀行轉帳",
    "信用卡"
  ].freeze

  DEFAULT_PAYMENT_PLATFORMS = [
    "LINE Pay",
    "Apple Pay",
    "Google Pay",
    "悠遊付",
    "街口支付"
  ].freeze

  DEFAULT_PAYMENT_METHOD_REQUIRING_PLATFORM = "行動支付"

  CREDIT_CARD_PAYMENT_KINDS = [
    "分期付款",
    "一次支付"
  ].freeze

  PAYMENT_TIMINGS = [
    "本月支付",
    "次月支付"
  ].freeze

  DEFAULTS_BY_KIND = {
    "category" => DEFAULT_CATEGORIES,
    "payment_method" => DEFAULT_PAYMENT_METHODS,
    "payment_platform" => DEFAULT_PAYMENT_PLATFORMS
  }.freeze

  class Catalog
    def initialize(user)
      @user = user
      ExpenditureTaxonomy.ensure_seeded!(@user) if @user
    end

    def categories
      names_for("category")
    end

    def payment_methods
      names_for("payment_method")
    end

    def payment_platforms
      names_for("payment_platform")
    end

    def payment_methods_requiring_platform
      return ExpenditureTaxonomy.default_payment_methods_requiring_platform unless persisted_taxonomy_available?
      return ExpenditureTaxonomy.default_payment_methods_requiring_platform unless @user

      methods = ExpenditureTaxonomyItem.for_kind("payment_method").where(user: @user)
      return ExpenditureTaxonomy.default_payment_methods_requiring_platform unless methods.exists?

      names = methods.where(requires_payment_platform: true).pluck(:name)
      names.presence || ExpenditureTaxonomy.default_payment_methods_requiring_platform
    end

    def names_for(kind)
      defaults = DEFAULTS_BY_KIND.fetch(kind, [])
      return defaults unless ExpenditureTaxonomy.persisted_taxonomy_available?
      return defaults unless @user

      ExpenditureTaxonomyItem.for_kind(kind).where(user: @user).pluck(:name)
    end

    def items_for(kind)
      return ExpenditureTaxonomyItem.none unless persisted_taxonomy_available? && @user

      ExpenditureTaxonomyItem.for_kind(kind).where(user: @user)
    end

    private

    def persisted_taxonomy_available?
      ExpenditureTaxonomy.persisted_taxonomy_available?
    end
  end

  def self.for_user(user)
    Catalog.new(user)
  end

  def self.persisted_taxonomy_available?
    return @persisted_taxonomy_available unless @persisted_taxonomy_available.nil?

    @persisted_taxonomy_available = ActiveRecord::Base.connection.table_exists?(:expenditure_taxonomy_items)
  rescue StandardError
    @persisted_taxonomy_available = false
  end

  def self.default_payment_methods_requiring_platform
    [ DEFAULT_PAYMENT_METHOD_REQUIRING_PLATFORM ].freeze
  end

  def self.ensure_seeded!(user)
    return unless user
    return unless persisted_taxonomy_available?
    return if ExpenditureTaxonomyItem.where(user: user).exists?

    ExpenditureTaxonomyItem.transaction do
      DEFAULTS_BY_KIND.each do |kind, names|
        names.each_with_index do |name, index|
          ExpenditureTaxonomyItem.create!(
            user: user,
            kind: kind,
            name: name,
            position: index,
            requires_payment_platform: kind == "payment_method" && name == DEFAULT_PAYMENT_METHOD_REQUIRING_PLATFORM
          )
        end
      end
    end
  end
end
