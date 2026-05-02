class CreateCalenderMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :calender_months do |t|
      t.integer :month, null: false
      t.integer :year, null: false
      t.timestamps
    end
  end
end