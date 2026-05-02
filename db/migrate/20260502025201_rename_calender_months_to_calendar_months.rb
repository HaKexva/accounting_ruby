class RenameCalenderMonthsToCalendarMonths < ActiveRecord::Migration[8.1]
  def change
    rename_table :calender_months, :calendar_months
    add_index :calendar_months, %i[year month], unique: true
  end
end
