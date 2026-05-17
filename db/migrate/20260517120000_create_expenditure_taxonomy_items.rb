# frozen_string_literal: true

class CreateExpenditureTaxonomyItems < ActiveRecord::Migration[8.1]
  def change
    create_table :expenditure_taxonomy_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :expenditure_taxonomy_items, %i[user_id kind name], unique: true
    add_index :expenditure_taxonomy_items, %i[user_id kind position]
  end
end
