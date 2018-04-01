class CreatePlayers < ActiveRecord::Migration[5.1]
  def change
    create_table :players do |t|
      t.integer :nba_id, null: false
      t.string :display_name
      t.string :first_name
      t.string :last_name
      t.integer :roster_status
      t.integer :from_year
      t.integer :to_year
      t.string :player_code
      t.integer :team_id
      t.string :team_city
      t.string :team_name
      t.string :team_abbreviation
      t.string :team_code
      t.string :games_played_flag
      t.timestamps
    end

    add_index :players, :nba_id, unique: true
  end
end
