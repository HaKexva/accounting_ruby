class AddUsersAndCalendarMonthsToAllTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :revenue_budget, :user, null: false
    add_reference :expenditure_budget, :user, null: false
    add_reference :actual_expenditure, :user, null: false
    add_reference :calendar_months, :user, null: false
    add_reference :revenue_budget, :calendar_month, null: false
    add_reference :expenditure_budget, :calendar_month, null: false
    add_reference :actual_expenditure, :calendar_month, null: false
  end
end
