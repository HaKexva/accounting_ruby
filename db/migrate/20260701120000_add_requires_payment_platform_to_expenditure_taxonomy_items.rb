# frozen_string_literal: true

class AddRequiresPaymentPlatformToExpenditureTaxonomyItems < ActiveRecord::Migration[8.1]
  def change
    add_column :expenditure_taxonomy_items, :requires_payment_platform, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE expenditure_taxonomy_items
          SET requires_payment_platform = TRUE
          WHERE kind = 'payment_method' AND name = '多元支付'
        SQL
      end
    end
  end
end
