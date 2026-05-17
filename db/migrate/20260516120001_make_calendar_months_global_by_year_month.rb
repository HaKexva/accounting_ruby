# frozen_string_literal: true

class MakeCalendarMonthsGlobalByYearMonth < ActiveRecord::Migration[8.1]
  class CalendarMonthRow < ActiveRecord::Base
    self.table_name = "calendar_months"
  end

  class ActualExpenditureRow < ActiveRecord::Base
    self.table_name = "actual_expenditures"
  end

  class RevenueBudgetRow < ActiveRecord::Base
    self.table_name = "revenue_budgets"
  end

  class ExpenditureBudgetRow < ActiveRecord::Base
    self.table_name = "expenditure_budgets"
  end

  def up
    remove_index :calendar_months, name: "index_calendar_months_on_user_id_and_year_and_month"
    merge_duplicate_calendar_month_rows!
    remove_index :calendar_months, name: "index_calendar_months_on_user_id"
    remove_column :calendar_months, :user_id, :integer
    add_index :calendar_months, %i[year month], unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def merge_duplicate_calendar_month_rows!
    CalendarMonthRow.order(:year, :month, :id).group_by { |row| [ row.year, row.month ] }.each_value do |rows|
      next if rows.size <= 1

      keeper = rows.first
      rows.drop(1).each do |dup|
        ActualExpenditureRow.where(calendar_month_id: dup.id).update_all(calendar_month_id: keeper.id)
        RevenueBudgetRow.where(calendar_month_id: dup.id).update_all(calendar_month_id: keeper.id)
        ExpenditureBudgetRow.where(calendar_month_id: dup.id).update_all(calendar_month_id: keeper.id)
        dup.delete
      end
    end
  end
end
