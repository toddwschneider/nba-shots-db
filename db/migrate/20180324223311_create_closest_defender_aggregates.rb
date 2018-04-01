class CreateClosestDefenderAggregates < ActiveRecord::Migration[5.1]
  def change
    create_table :closest_defender_aggregates do |t|
      t.integer :player_nba_id, null: false
      t.string :season
      t.string :season_type
      t.string :shot_distance_range
      t.string :closest_defender_range
      t.integer :fgm
      t.integer :fga
      t.integer :fg2m
      t.integer :fg2a
      t.integer :fg3m
      t.integer :fg3a
      t.timestamps
    end

    add_index :closest_defender_aggregates, :player_nba_id
  end
end
