def normalize_name(name)
  name.
    downcase.
    gsub(/[^[[:word:]]\s-]/, "").
    squish
end

ncaa_players = Player.find_by_sql("SELECT * FROM ncaa_players")

grouped_ncaa_players = ncaa_players.group_by do |ncaa_player|
  normalize_name(ncaa_player.player_full_name)
end

first_ncaa_season = ncaa_players.map(&:first_season).min

# only consider players who first appeared in the NBA after the NCAA data starts
nba_players_scope = Player.where("from_year >= ?", first_ncaa_season + 1)

players_mapping = {}
for_manual_review = []
unmapped = []

nba_players_scope.each do |nba_player|
  normalized_nba_name = normalize_name(nba_player.display_name)

  candidates = grouped_ncaa_players[normalized_nba_name].to_a.select do |candidate|
    candidate.last_season < nba_player.from_year
  end

  if candidates.size > 1
    for_manual_review << [nba_player, candidates]
  elsif candidates.size == 1
    players_mapping[nba_player.nba_id] = candidates.first.player_id
  else
    unmapped << nba_player
  end
end

manually_reviewed = {
  259 => 'dca8aa79-e4e1-4f05-85a0-a6f06d7de321',
  1816 => '470578cc-ba78-422b-a27c-6278446b4dda',
  1969 => 'deb2e62d-337a-409a-9861-4b4cee35e1aa',
  2600 => '4d06fcc3-2b55-4749-b67e-71582ceb59a1',
  3782 => 'b9a18133-65b5-4f05-9d23-6e3e2d4e39c1'
}

players_mapping.merge!(manually_reviewed)

require 'csv'
CSV.open("#{Rails.root}/app/lib/ncaa_shots/players_mapping.csv", "wb") do |csv|
  csv << %w(nba_id ncaa_id)
  players_mapping.each { |k, v| csv << [k, v] }
end
