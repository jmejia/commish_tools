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

ActiveRecord::Schema[8.0].define(version: 2025_06_28_223537) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "league_memberships", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.bigint "user_id", null: false
    t.string "sleeper_user_id"
    t.string "team_name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_league_memberships_on_league_id"
    t.index ["user_id"], name: "index_league_memberships_on_user_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.string "sleeper_league_id"
    t.string "name"
    t.integer "season_year"
    t.jsonb "settings"
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_leagues_on_owner_id"
    t.index ["sleeper_league_id"], name: "index_leagues_on_sleeper_league_id", unique: true
  end

  create_table "press_conference_questions", force: :cascade do |t|
    t.bigint "press_conference_id", null: false
    t.text "question_text"
    t.string "question_audio_url"
    t.string "playht_question_voice_id"
    t.integer "order_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["press_conference_id"], name: "index_press_conference_questions_on_press_conference_id"
  end

  create_table "press_conference_responses", force: :cascade do |t|
    t.bigint "press_conference_question_id", null: false
    t.text "response_text"
    t.string "response_audio_url"
    t.text "generation_prompt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["press_conference_question_id"], name: "idx_on_press_conference_question_id_326d987559"
  end

  create_table "press_conferences", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.bigint "target_manager_id", null: false
    t.integer "week_number"
    t.integer "season_year"
    t.integer "status"
    t.jsonb "context_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_press_conferences_on_league_id"
    t.index ["target_manager_id"], name: "index_press_conferences_on_target_manager_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "voice_clones", force: :cascade do |t|
    t.bigint "league_membership_id", null: false
    t.string "playht_voice_id"
    t.string "original_audio_url"
    t.integer "status"
    t.string "upload_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_membership_id"], name: "index_voice_clones_on_league_membership_id"
  end

  add_foreign_key "league_memberships", "leagues"
  add_foreign_key "league_memberships", "users"
  add_foreign_key "leagues", "users", column: "owner_id"
  add_foreign_key "press_conference_questions", "press_conferences"
  add_foreign_key "press_conference_responses", "press_conference_questions"
  add_foreign_key "press_conferences", "league_memberships", column: "target_manager_id"
  add_foreign_key "press_conferences", "leagues"
  add_foreign_key "voice_clones", "league_memberships"
end
