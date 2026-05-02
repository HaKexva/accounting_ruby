class FixCalendarMonthsUniqueIndexPerUser < ActiveRecord::Migration[8.1]
  def change
    remove_index :calendar_months, name: "index_calendar_months_on_year_and_month"
    add_index :calendar_months, %i[user_id year month], unique: true
  end
end
