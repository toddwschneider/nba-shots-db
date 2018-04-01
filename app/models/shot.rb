class Shot < ApplicationRecord
  belongs_to :player, primary_key: :nba_id, foreign_key: :player_nba_id

  validates :player_nba_id, presence: true

  class << self
    def create_all
      Player.import_all_without_delay

      client.all_years.each do |year|
        create_all_by(year: year, season_type: "Regular Season")
        create_all_by(year: year, season_type: "Playoffs")
      end
    end
    handle_asynchronously :create_all

    def create_all_by(year:, season_type: "Regular Season")
      raise "invalid year" unless client.all_years.include?(year)
      raise "invalid season type" unless client.season_types.include?(season_type)

      Player.
        select(:id).
        where("from_year <= ? AND to_year >= ?", year, year).
        find_each do |player|
          player.create_shots(
            season: client.year_to_season(year),
            season_type: season_type
          )
        end
    end
    handle_asynchronously :create_all_by
  end

  private

  def self.client
    @client ||= NbaStatsClient.new
  end
end
