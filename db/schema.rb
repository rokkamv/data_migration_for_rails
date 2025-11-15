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

ActiveRecord::Schema[7.1].define(version: 2025_11_05_222623) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "migration_executions", force: :cascade do |t|
    t.bigint "migration_plan_id", null: false
    t.bigint "user_id", null: false
    t.integer "execution_type", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "file_path"
    t.jsonb "stats", default: {}
    t.text "error_log"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_type"], name: "index_migration_executions_on_execution_type"
    t.index ["migration_plan_id"], name: "index_migration_executions_on_migration_plan_id"
    t.index ["started_at"], name: "index_migration_executions_on_started_at"
    t.index ["status"], name: "index_migration_executions_on_status"
    t.index ["user_id"], name: "index_migration_executions_on_user_id"
  end

  create_table "migration_plans", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_migration_plans_on_name", unique: true
  end

  create_table "migration_records", force: :cascade do |t|
    t.bigint "migration_execution_id", null: false
    t.string "migrated_model_name"
    t.string "record_identifier"
    t.integer "action"
    t.jsonb "record_changes"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["migration_execution_id"], name: "index_migration_records_on_migration_execution_id"
  end

  create_table "migration_steps", force: :cascade do |t|
    t.bigint "migration_plan_id", null: false
    t.string "model_name"
    t.integer "sequence"
    t.string "filter_query"
    t.bigint "dependee_id"
    t.jsonb "dependee_attribute_mapping", default: {}
    t.jsonb "column_overrides", default: {}
    t.jsonb "association_overrides", default: {}
    t.string "included_models", default: [], array: true
    t.string "excluded_models", default: [], array: true
    t.jsonb "model_filters", default: {}
    t.jsonb "association_selections", default: {}
    t.jsonb "polymorphic_associations", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dependee_id"], name: "index_migration_steps_on_dependee_id"
    t.index ["migration_plan_id"], name: "index_migration_steps_on_migration_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "migration_executions", "migration_plans"
  add_foreign_key "migration_executions", "users"
  add_foreign_key "migration_records", "migration_executions"
  add_foreign_key "migration_steps", "migration_plans"
  add_foreign_key "migration_steps", "migration_steps", column: "dependee_id"
end
