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
end
