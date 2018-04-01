class Player < ApplicationRecord
  has_many :shots,
    inverse_of: :player,
    primary_key: :nba_id,
    foreign_key: :player_nba_id,
    dependent: :destroy

  has_many :closest_defender_aggregates,
    inverse_of: :player,
    primary_key: :nba_id,
    foreign_key: :player_nba_id,
    dependent: :destroy

  validates :nba_id, presence: true, uniqueness: true

  def create_shots(season: "2017-18", season_type: "Regular Season")
    player_shots = fetch_shots(season: season, season_type: season_type)

    copy_schema = "player_nba_id, season, season_type, grid_type, game_id, game_event_id, team_id, team_name, period, minutes_remaining, seconds_remaining, event_type, action_type, shot_type, shot_zone_basic, shot_zone_area, shot_zone_range, shot_distance, loc_x, loc_y, shot_attempted_flag, shot_made_flag, game_date, home_team, visiting_team, created_at, updated_at"

    sql_statement = "COPY shots (#{copy_schema}) FROM stdin;"

    now = Time.zone.now

    transaction do
      shots.where(season: season, season_type: season_type).delete_all

      pg_connection.copy_data(sql_statement, copy_encoder) do
        player_shots.each do |row|
          row_for_copy = [
            row.player_id,
            season,
            season_type,
            row.grid_type,
            row.game_id,
            row.game_event_id,
            row.team_id,
            row.team_name,
            row.period,
            row.minutes_remaining,
            row.seconds_remaining,
            row.event_type,
            row.action_type,
            row.shot_type,
            row.shot_zone_basic,
            row.shot_zone_area,
            row.shot_zone_range,
            row.shot_distance,
            row.loc_x,
            row.loc_y,
            row.shot_attempted_flag,
            row.shot_made_flag,
            row.game_date,
            row.htm,
            row.vtm,
            now,
            now
          ]

          pg_connection.put_copy_data(row_for_copy)
        end
      end
    end
  end
  handle_asynchronously :create_shots, queue: :create_shots

  def fetch_shots(season: "2017-18", season_type: "Regular Season")
    client.shots(
      player_id: nba_id,
      season: season,
      season_type: season_type
    )
  end

  class << self
    def import_all
      client.all_players.each do |row|
        player = find_or_initialize_by(nba_id: row.person_id)

        player.display_name = row.display_first_last
        player.first_name = row.display_last_comma_first.split(",", 2).last.squish
        player.last_name = row.display_last_comma_first.split(",", 2).first.squish
        player.roster_status = row.rosterstatus
        player.from_year = row.from_year
        player.to_year = row.to_year
        player.player_code = row.playercode
        player.team_id = row.team_id
        player.team_city = row.team_city
        player.team_name = row.team_name
        player.team_abbreviation = row.team_abbreviation
        player.team_code = row.team_code
        player.games_played_flag = row.games_played_flag

        player.save!
      end
    end
    handle_asynchronously :import_all
  end

  private

  def self.client
    @client ||= NbaStatsClient.new
  end
  delegate :client, to: 'self.class'

  def pg_connection
    self.class.connection.raw_connection
  end

  def copy_encoder
    PG::TextEncoder::CopyRow.new
  end
end
