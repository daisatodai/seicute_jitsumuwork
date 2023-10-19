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

ActiveRecord::Schema.define(version: 2023_10_16_061258) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "invoice_details", force: :cascade do |t|
    t.string "subject", null: false
    t.integer "unit_price", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "invoice_id", null: false
    t.index ["invoice_id"], name: "index_invoice_details_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "subject", null: false
    t.date "issued_on", null: false
    t.date "due_on", null: false
    t.text "error"
    t.integer "google_drive_api_status", default: 0, null: false
    t.integer "freee_api_status", default: 0, null: false
    t.text "memo"
    t.bigint "freee_deal_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "requestor_id", null: false
    t.bigint "user_id", null: false
    t.index ["requestor_id"], name: "index_invoices_on_requestor_id"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "pictures", force: :cascade do |t|
    t.text "image", null: false
    t.text "google_drive_url"
    t.text "google_drive_file_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "invoice_id", null: false
    t.index ["invoice_id"], name: "index_pictures_on_invoice_id"
  end

  create_table "requestors", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_requestors_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "role", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "invoice_details", "invoices"
  add_foreign_key "invoices", "requestors"
  add_foreign_key "invoices", "users"
  add_foreign_key "pictures", "invoices"
end
