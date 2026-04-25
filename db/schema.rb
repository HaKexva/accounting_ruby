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

ActiveRecord::Schema[8.1].define(version: 2026_04_25_071240) do
  create_table "budget_expenses", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "item", null: false
    t.text "note"
    t.date "time", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_budget_expenses_on_category"
    t.index ["time"], name: "index_budget_expenses_on_time"
  end

  create_table "budget_incomes", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "item", null: false
    t.text "note"
    t.date "time", null: false
    t.datetime "updated_at", null: false
    t.index ["time"], name: "index_budget_incomes_on_time"
  end

  create_table "real_expenses", force: :cascade do |t|
    t.decimal "actual_amount", precision: 12, scale: 2, null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "credit_card_payment_method"
    t.text "note"
    t.string "payment_method", null: false
    t.string "payment_platform"
    t.string "payment_timing"
    t.decimal "posted_amount", precision: 12, scale: 2
    t.date "transaction_date", null: false
    t.string "transaction_item", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_real_expenses_on_category"
    t.index ["payment_method"], name: "index_real_expenses_on_payment_method"
    t.index ["transaction_date"], name: "index_real_expenses_on_transaction_date"
  end
end
