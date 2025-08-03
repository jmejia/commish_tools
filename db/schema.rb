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

ActiveRecord::Schema[8.0].define(version: 2025_08_03_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "draft_grades", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.bigint "user_id", null: false
    t.bigint "draft_id"
    t.string "grade", null: false
    t.integer "projected_rank", null: false
    t.decimal "projected_points", precision: 10, scale: 2
    t.decimal "projected_wins", precision: 4, scale: 2
    t.decimal "playoff_probability", precision: 5, scale: 2
    t.jsonb "position_grades", default: {}
    t.jsonb "best_picks", default: []
    t.jsonb "worst_picks", default: []
    t.jsonb "analysis", default: {}
    t.datetime "calculated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis"], name: "index_draft_grades_on_analysis", using: :gin
    t.index ["calculated_at"], name: "index_draft_grades_on_calculated_at"
    t.index ["draft_id"], name: "index_draft_grades_on_draft_id"
    t.index ["grade"], name: "index_draft_grades_on_grade"
    t.index ["league_id", "projected_rank"], name: "index_draft_grades_on_league_id_and_projected_rank"
    t.index ["league_id", "user_id", "draft_id"], name: "index_draft_grades_on_league_id_and_user_id_and_draft_id", unique: true
    t.index ["league_id"], name: "index_draft_grades_on_league_id"
    t.index ["position_grades"], name: "index_draft_grades_on_position_grades", using: :gin
    t.index ["user_id"], name: "index_draft_grades_on_user_id"
  end

  create_table "draft_picks", force: :cascade do |t|
    t.bigint "draft_id", null: false
    t.bigint "user_id", null: false
    t.string "sleeper_player_id", null: false
    t.string "sleeper_user_id", null: false
    t.integer "round", null: false
    t.integer "pick_number", null: false
    t.integer "overall_pick", null: false
    t.string "player_name"
    t.string "position"
    t.decimal "projected_points", precision: 10, scale: 2
    t.decimal "actual_points", precision: 10, scale: 2
    t.decimal "value_over_replacement", precision: 10, scale: 2
    t.integer "adp"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draft_id", "overall_pick"], name: "index_draft_picks_on_draft_id_and_overall_pick", unique: true
    t.index ["draft_id", "user_id"], name: "index_draft_picks_on_draft_id_and_user_id"
    t.index ["draft_id"], name: "index_draft_picks_on_draft_id"
    t.index ["metadata"], name: "index_draft_picks_on_metadata", using: :gin
    t.index ["position"], name: "index_draft_picks_on_position"
    t.index ["sleeper_player_id"], name: "index_draft_picks_on_sleeper_player_id"
    t.index ["user_id"], name: "index_draft_picks_on_user_id"
  end

  create_table "drafts", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.string "sleeper_draft_id", null: false
    t.string "season_year", null: false
    t.string "status", null: false
    t.jsonb "settings", default: {}
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_drafts_on_completed_at"
    t.index ["league_id", "season_year"], name: "index_drafts_on_league_id_and_season_year"
    t.index ["league_id"], name: "index_drafts_on_league_id"
    t.index ["settings"], name: "index_drafts_on_settings", using: :gin
    t.index ["sleeper_draft_id"], name: "index_drafts_on_sleeper_draft_id", unique: true
    t.index ["status"], name: "index_drafts_on_status"
  end

  create_table "event_time_slots", force: :cascade do |t|
    t.bigint "scheduling_poll_id", null: false
    t.datetime "starts_at", null: false
    t.integer "duration_minutes", default: 60, null: false
    t.jsonb "slot_metadata", default: {}
    t.integer "order_index", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduling_poll_id", "starts_at"], name: "index_event_time_slots_on_poll_and_start_time"
    t.index ["scheduling_poll_id"], name: "index_event_time_slots_on_scheduling_poll_id"
    t.index ["starts_at", "duration_minutes"], name: "index_event_time_slots_on_time_and_duration"
    t.index ["starts_at"], name: "index_event_time_slots_on_starts_at"
  end

  create_table "league_contexts", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "content"
    t.index ["league_id"], name: "index_league_contexts_on_league_id"
  end

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
    t.string "final_audio_url"
    t.index ["league_id"], name: "index_press_conferences_on_league_id"
    t.index ["target_manager_id"], name: "index_press_conferences_on_target_manager_id"
  end

  create_table "scheduling_polls", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.bigint "created_by_id", null: false
    t.string "public_token", null: false
    t.string "event_type", default: "draft", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.datetime "closes_at"
    t.jsonb "settings", default: {}
    t.jsonb "event_metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closes_at"], name: "index_scheduling_polls_on_closes_at"
    t.index ["created_by_id", "status"], name: "index_scheduling_polls_on_creator_status"
    t.index ["created_by_id"], name: "index_scheduling_polls_on_created_by_id"
    t.index ["event_type"], name: "index_scheduling_polls_on_event_type"
    t.index ["league_id", "event_type"], name: "index_scheduling_polls_on_league_id_and_event_type"
    t.index ["league_id", "status", "event_type"], name: "index_scheduling_polls_on_league_status_event"
    t.index ["league_id"], name: "index_scheduling_polls_on_league_id"
    t.index ["public_token"], name: "index_scheduling_polls_on_public_token", unique: true
    t.index ["settings"], name: "index_scheduling_polls_on_settings", using: :gin
    t.index ["status"], name: "index_scheduling_polls_on_status"
  end

  create_table "scheduling_responses", force: :cascade do |t|
    t.bigint "scheduling_poll_id", null: false
    t.string "respondent_name", null: false
    t.string "respondent_identifier", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ip_address", "created_at"], name: "index_scheduling_responses_on_ip_and_created"
    t.index ["ip_address"], name: "index_scheduling_responses_on_ip_address"
    t.index ["metadata"], name: "index_scheduling_responses_on_metadata", using: :gin
    t.index ["scheduling_poll_id", "created_at"], name: "index_scheduling_responses_on_poll_and_created"
    t.index ["scheduling_poll_id", "respondent_identifier"], name: "index_scheduling_responses_on_poll_and_identifier", unique: true
    t.index ["scheduling_poll_id"], name: "index_scheduling_responses_on_scheduling_poll_id"
  end

  create_table "sleeper_connection_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "sleeper_username", null: false
    t.string "sleeper_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "requested_at", precision: nil, null: false
    t.datetime "reviewed_at", precision: nil
    t.bigint "reviewed_by_id"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewed_by_id"], name: "index_sleeper_connection_requests_on_reviewed_by_id"
    t.index ["status"], name: "index_sleeper_connection_requests_on_status"
    t.index ["user_id"], name: "index_sleeper_connection_requests_on_user_id"
  end

  create_table "slot_availabilities", force: :cascade do |t|
    t.bigint "scheduling_response_id", null: false
    t.bigint "event_time_slot_id", null: false
    t.integer "availability", null: false
    t.jsonb "preference_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_time_slot_id", "availability"], name: "index_slot_availabilities_on_slot_and_availability"
    t.index ["event_time_slot_id"], name: "index_slot_availabilities_on_event_time_slot_id"
    t.index ["scheduling_response_id", "event_time_slot_id"], name: "index_slot_availability_unique", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "super_admins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_super_admins_on_user_id", unique: true
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
    t.string "sleeper_username"
    t.string "sleeper_id"
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

  create_table "voice_upload_links", force: :cascade do |t|
    t.bigint "voice_clone_id", null: false
    t.string "public_token", null: false
    t.string "title"
    t.text "instructions"
    t.datetime "expires_at"
    t.boolean "active", default: true, null: false
    t.integer "max_uploads", default: 1, null: false
    t.integer "upload_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["public_token"], name: "index_voice_upload_links_on_public_token", unique: true
    t.index ["voice_clone_id"], name: "index_voice_upload_links_on_voice_clone_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "draft_grades", "drafts"
  add_foreign_key "draft_grades", "leagues"
  add_foreign_key "draft_grades", "users"
  add_foreign_key "draft_picks", "drafts"
  add_foreign_key "draft_picks", "users"
  add_foreign_key "drafts", "leagues"
  add_foreign_key "event_time_slots", "scheduling_polls"
  add_foreign_key "league_contexts", "leagues"
  add_foreign_key "league_memberships", "leagues"
  add_foreign_key "league_memberships", "users"
  add_foreign_key "leagues", "users", column: "owner_id"
  add_foreign_key "press_conference_questions", "press_conferences"
  add_foreign_key "press_conference_responses", "press_conference_questions"
  add_foreign_key "press_conferences", "league_memberships", column: "target_manager_id"
  add_foreign_key "press_conferences", "leagues"
  add_foreign_key "scheduling_polls", "leagues"
  add_foreign_key "scheduling_polls", "users", column: "created_by_id"
  add_foreign_key "scheduling_responses", "scheduling_polls"
  add_foreign_key "sleeper_connection_requests", "users"
  add_foreign_key "sleeper_connection_requests", "users", column: "reviewed_by_id"
  add_foreign_key "slot_availabilities", "event_time_slots"
  add_foreign_key "slot_availabilities", "scheduling_responses"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "super_admins", "users"
  add_foreign_key "voice_clones", "league_memberships"
  add_foreign_key "voice_upload_links", "voice_clones"
end
