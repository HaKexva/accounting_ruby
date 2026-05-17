# frozen_string_literal: true

require "test_helper"

class ExpenditureTaxonomyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    ExpenditureTaxonomyItem.where(user: @user).delete_all
  end

  test "ensure_seeded! creates default items per kind" do
    assert_difference -> { ExpenditureTaxonomyItem.where(user: @user).count },
                      ExpenditureTaxonomy::DEFAULT_CATEGORIES.size +
                        ExpenditureTaxonomy::DEFAULT_PAYMENT_METHODS.size +
                        ExpenditureTaxonomy::DEFAULT_PAYMENT_PLATFORMS.size do
      ExpenditureTaxonomy.ensure_seeded!(@user)
    end
  end

  test "for_user catalog returns seeded category names" do
    catalog = ExpenditureTaxonomy.for_user(@user)
    assert_equal ExpenditureTaxonomy::DEFAULT_CATEGORIES, catalog.categories
  end

  test "for_user falls back to defaults when taxonomy table is missing" do
    conn = ActiveRecord::Base.connection
    conn.execute("ALTER TABLE expenditure_taxonomy_items RENAME TO _taxonomy_missing_test") if conn.table_exists?(:expenditure_taxonomy_items)
    ExpenditureTaxonomy.instance_variable_set(:@persisted_taxonomy_available, nil)

    catalog = ExpenditureTaxonomy.for_user(@user)
    assert_equal ExpenditureTaxonomy::DEFAULT_CATEGORIES, catalog.categories
  ensure
    ExpenditureTaxonomy.instance_variable_set(:@persisted_taxonomy_available, nil)
    conn.execute("ALTER TABLE _taxonomy_missing_test RENAME TO expenditure_taxonomy_items") if conn.table_exists?(:_taxonomy_missing_test)
  end
end
