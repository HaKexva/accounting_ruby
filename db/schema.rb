# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_01_120000) do
  create_table "actual_expenditures", force: :cascade do |t|
    t.decimal "actual_amount", null: false
    t.integer "calendar_month_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "credit_card_payment_method"
    t.text "note"
    t.string "payment_method", null: false
    t.string "payment_platform"
    t.string "payment_timing"
    t.decimal "posted_amount", null: false
    t.date "transaction_date", null: false
    t.string "transaction_item", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["calendar_month_id"], name: "index_actual_expenditures_on_calendar_month_id"
    t.index ["transaction_date", "transaction_item"], name: "idx_on_transaction_date_transaction_item_05330fe101"
    t.index ["user_id"], name: "index_actual_expenditures_on_user_id"
  end

  create_table "calendar_months", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "month", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["year", "month"], name: "index_calendar_months_on_year_and_month", unique: true
  end

  create_table "expenditure_budgets", force: :cascade do |t|
    t.decimal "amount", null: false
    t.integer "calendar_month_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "item", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["calendar_month_id"], name: "index_expenditure_budgets_on_calendar_month_id"
    t.index ["user_id"], name: "index_expenditure_budgets_on_user_id"
  end

  create_table "expenditure_taxonomy_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "requires_payment_platform", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "kind", "name"], name: "index_expenditure_taxonomy_items_on_user_id_and_kind_and_name", unique: true
    t.index ["user_id", "kind", "position"], name: "idx_on_user_id_kind_position_21e3a4f6f2"
    t.index ["user_id"], name: "index_expenditure_taxonomy_items_on_user_id"
  end

  create_table "revenue_budgets", force: :cascade do |t|
    t.decimal "amount", null: false
    t.integer "calendar_month_id", null: false
    t.datetime "created_at", null: false
    t.string "item", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["calendar_month_id"], name: "index_revenue_budgets_on_calendar_month_id"
    t.index ["user_id"], name: "index_revenue_budgets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "google_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "expenditure_taxonomy_items", "users"
end
