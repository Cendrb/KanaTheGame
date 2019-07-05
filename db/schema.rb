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

ActiveRecord::Schema.define(version: 20190705133602) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "fulfilled_shapes", force: :cascade do |t|
    t.integer  "shape_id"
    t.integer  "match_id"
    t.integer  "player_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.text     "board_data"
    t.boolean  "traded",     default: false, null: false
  end

  create_table "match_signups", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "match_id"
    t.integer  "player_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "spent_points"
    t.boolean  "lost",         default: false, null: false
  end

  create_table "matches", force: :cascade do |t|
    t.text     "board_data"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "currently_playing_id"
    t.integer  "players_count"
    t.integer  "match_type"
    t.string   "password"
    t.integer  "state",                default: 0
    t.datetime "finished_on"
  end

  create_table "players", force: :cascade do |t|
    t.string   "name"
    t.integer  "priority"
    t.string   "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shapes", force: :cascade do |t|
    t.string   "name"
    t.integer  "points"
    t.text     "board_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "nickname"
    t.string   "hashed_password"
    t.string   "salt"
    t.integer  "access_level"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "elo"
    t.integer  "current_match_id"
  end

end
