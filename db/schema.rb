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

ActiveRecord::Schema[8.0].define(version: 2025_08_17_000137) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "care_recipients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "relationship"
    t.text "conditions", array: true
    t.string "insurance_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_care_recipients_on_user_id"
  end

  create_table "expenses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "amount"
    t.datetime "date"
    t.string "category"
    t.string "subcategory"
    t.string "description"
    t.string "receipt_url"
    t.text "expense_tags", default: [], array: true
    t.boolean "is_tax_deductible"
    t.boolean "is_reimbursed"
    t.boolean "is_potentially_deductible"
    t.string "reimbursement_source"
    t.string "synced_transaction_id"
    t.uuid "user_id", null: false
    t.uuid "care_recipient_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount"], name: "index_expenses_on_amount"
    t.index ["care_recipient_id"], name: "index_expenses_on_care_recipient_id"
    t.index ["category"], name: "index_expenses_on_category"
    t.index ["date"], name: "index_expenses_on_date"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "linked_accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.boolean "is_active"
    t.integer "account_type"
    t.string "account_name"
    t.string "institution_name"
    t.string "plaid_access_token"
    t.string "plaid_account_id"
    t.string "stripe_account_id"
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "last_sync_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_type"], name: "index_linked_accounts_on_account_type"
    t.index ["is_active"], name: "index_linked_accounts_on_is_active"
    t.index ["user_id"], name: "index_linked_accounts_on_user_id"
  end

  create_table "resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "category"
    t.string "description"
    t.string "link"
    t.boolean "is_favorite"
    t.integer "resource_type", null: false
    t.string "partner_name"
    t.text "tags", default: [], array: true
    t.text "zip_regions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "synced_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "linked_account_id", null: false
    t.uuid "expense_id", null: false
    t.string "transaction_id"
    t.integer "amount"
    t.datetime "date"
    t.text "description"
    t.string "merchant_name"
    t.string "category"
    t.boolean "is_potential_medical"
    t.boolean "is_confirmed_medical"
    t.boolean "is_tax_deductible"
    t.boolean "is_reimbursed"
    t.string "reimbursement_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_synced_transactions_on_date"
    t.index ["expense_id"], name: "index_synced_transactions_on_expense_id"
    t.index ["linked_account_id"], name: "index_synced_transactions_on_linked_account_id"
    t.index ["user_id"], name: "index_synced_transactions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.boolean "is_caregiver"
    t.text "caregiving_for", default: [], array: true
    t.integer "household_agi"
    t.boolean "onboarding_complete"
    t.string "zip_code"
    t.string "state"
    t.string "county"
    t.text "caregiver_role", default: [], array: true
    t.integer "number_of_dependents"
    t.string "employment_status"
    t.string "tax_filing_status"
    t.text "health_coverage_type", default: [], array: true
    t.text "primary_caregiving_expenses", default: [], array: true
    t.text "preferred_notification_method", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "care_recipients", "users"
  add_foreign_key "expenses", "care_recipients"
  add_foreign_key "expenses", "users"
  add_foreign_key "linked_accounts", "users"
  add_foreign_key "synced_transactions", "expenses"
  add_foreign_key "synced_transactions", "linked_accounts"
  add_foreign_key "synced_transactions", "users"
end
