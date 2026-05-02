class AddUsersAndCalendarMonthsToAllTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :revenue_budgets, :user, null: false
    add_reference :expenditure_budgets, :user, null: false
    add_reference :actual_expenditures, :user, null: false
    add_reference :calendar_months, :user, null: false
    add_reference :revenue_budgets, :calendar_month, null: false
    add_reference :expenditure_budgets, :calendar_month, null: false
    add_reference :actual_expenditures, :calendar_month, null: false
  end
end
