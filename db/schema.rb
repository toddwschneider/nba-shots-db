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

ActiveRecord::Schema.define(version: 20180324223311) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "closest_defender_aggregates", force: :cascade do |t|
    t.integer "player_nba_id", null: false
    t.string "season"
    t.string "season_type"
    t.string "shot_distance_range"
    t.string "closest_defender_range"
    t.integer "fgm"
    t.integer "fga"
    t.integer "fg2m"
    t.integer "fg2a"
    t.integer "fg3m"
    t.integer "fg3a"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_nba_id"], name: "index_closest_defender_aggregates_on_player_nba_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "players", force: :cascade do |t|
    t.integer "nba_id", null: false
    t.string "display_name"
    t.string "first_name"
    t.string "last_name"
    t.integer "roster_status"
    t.integer "from_year"
    t.integer "to_year"
    t.string "player_code"
    t.integer "team_id"
    t.string "team_city"
    t.string "team_name"
    t.string "team_abbreviation"
    t.string "team_code"
    t.string "games_played_flag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nba_id"], name: "index_players_on_nba_id", unique: true
  end

  create_table "shots", force: :cascade do |t|
    t.integer "player_nba_id", null: false
    t.string "season"
    t.string "season_type"
    t.string "grid_type"
    t.string "game_id"
    t.integer "game_event_id"
    t.integer "team_id"
    t.string "team_name"
    t.integer "period"
    t.integer "minutes_remaining"
    t.integer "seconds_remaining"
    t.string "event_type"
    t.string "action_type"
    t.string "shot_type"
    t.string "shot_zone_basic"
    t.string "shot_zone_area"
    t.string "shot_zone_range"
    t.integer "shot_distance"
    t.integer "loc_x"
    t.integer "loc_y"
    t.integer "shot_attempted_flag"
    t.integer "shot_made_flag"
    t.date "game_date"
    t.string "home_team"
    t.string "visiting_team"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_nba_id"], name: "index_shots_on_player_nba_id"
  end

end
