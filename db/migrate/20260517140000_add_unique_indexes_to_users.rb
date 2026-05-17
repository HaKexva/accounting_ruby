# frozen_string_literal: true

class AddUniqueIndexesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :google_uid, unique: true
    add_index :users, :email, unique: true
  end
end
