class CreateShots < ActiveRecord::Migration[5.1]
  def change
    create_table :shots do |t|
      t.integer :player_nba_id, null: false
      t.string :season
      t.string :season_type
      t.string :grid_type
      t.string :game_id
      t.integer :game_event_id
      t.integer :team_id
      t.string :team_name
      t.integer :period
      t.integer :minutes_remaining
      t.integer :seconds_remaining
      t.string :event_type
      t.string :action_type
      t.string :shot_type
      t.string :shot_zone_basic
      t.string :shot_zone_area
      t.string :shot_zone_range
      t.integer :shot_distance
      t.integer :loc_x
      t.integer :loc_y
      t.integer :shot_attempted_flag
      t.integer :shot_made_flag
      t.date :game_date
      t.string :home_team
      t.string :visiting_team
      t.timestamps
    end

    add_index :shots, :player_nba_id
  end
end
