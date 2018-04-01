class ClosestDefenderAggregate < ApplicationRecord
  SHOT_DISTANCE_RANGES = (0..31).each_cons(2).map { |a| a.join("-") }

  belongs_to :player, primary_key: :nba_id, foreign_key: :player_nba_id

  validates :player_nba_id, presence: true
  validates :shot_distance_range, inclusion: {in: SHOT_DISTANCE_RANGES}

  class << self
    def create_all
      all_combinations = client.closest_defender_seasons.product(
        client.season_types,
        client.closest_defender_ranges,
        SHOT_DISTANCE_RANGES
      )

      all_combinations.each do |season, season_type, closest_defender_range, shot_distance_range|
        create_all_by(
          season: season,
          season_type: season_type,
          closest_defender_range: closest_defender_range,
          shot_distance_range: shot_distance_range
        )
      end
    end
    handle_asynchronously :create_all

    def create_all_by(season:, season_type:, closest_defender_range:, shot_distance_range:)
      unless SHOT_DISTANCE_RANGES.include?(shot_distance_range)
        raise "invalid shot_distance_range"
      end

      min_shot_distance = shot_distance_range.split("-").first.to_i
      max_shot_distance = shot_distance_range.split("-").second.to_i

      upper = client.shot_stats_by_closest_defender(
        season: season,
        season_type: season_type,
        shot_dist_range: "<#{max_shot_distance}",
        close_def_dist_range: closest_defender_range,
      )

      lower = client.shot_stats_by_closest_defender(
        season: season,
        season_type: season_type,
        shot_dist_range: "<#{min_shot_distance}",
        close_def_dist_range: closest_defender_range,
      ).index_by(&:player_id)

      upper.each do |u|
        l = lower[u.player_id]

        fga = u.fga - l&.fga.to_i
        next if fga == 0

        record = find_or_initialize_by(
          season: season,
          season_type: season_type,
          player_nba_id: u.player_id,
          shot_distance_range: shot_distance_range,
          closest_defender_range: closest_defender_range
        )

        record.fgm = u.fgm - l&.fgm.to_i
        record.fga = fga
        record.fg2m = u.fg2m - l&.fg2m.to_i
        record.fg2a = u.fg2a - l&.fg2a.to_i
        record.fg3m = u.fg3m - l&.fg3m.to_i
        record.fg3a = u.fg3a - l&.fg3a.to_i

        record.save!
      end
    end
    handle_asynchronously :create_all_by
  end

  private

  def self.client
    @client ||= NbaStatsClient.new
  end
end
