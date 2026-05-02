class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :google_uid, null: false
      t.string :email, null: false
      t.timestamps
    end
  end
end
