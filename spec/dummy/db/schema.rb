# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170603141909) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "application_data_backups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "application_data_backups_glacier_file_archives", id: false, force: :cascade do |t|
    t.integer "application_data_backup_id", null: false
    t.integer "glacier_file_archive_id",    null: false
  end

  create_table "fake_model", id: false, force: :cascade do |t|
    t.string "file_id", limit: 255
  end

  create_table "fake_models", force: :cascade do |t|
    t.string   "file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "glacier_archives", force: :cascade do |t|
    t.text     "description"
    t.text     "archive_id"
    t.text     "checksum"
    t.text     "location"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.json     "notification"
    t.string   "archive_retrieval_job_id"
    t.integer  "application_data_backup_id"
    t.string   "type"
    t.string   "filename"
  end

  create_table "test", id: false, force: :cascade do |t|
    t.string "foo", limit: 255
  end

end
