-- college players who shoot best from NBA 3-point range
CREATE TABLE ncaa_players_from_nba_3_range AS
WITH shots_data AS (
  SELECT
    *,
    shot_distance > 23.75 OR abs(location_x) > 22 AS nba_3_range
  FROM merged_shots
  WHERE league_name = 'ncaa'
    AND shot_value = 3
    AND shot_distance < 32
)
SELECT
  player_ncaa_id,

  COUNT(*) AS fga3,
  SUM(shot_made::int) AS fgm3,
  SUM(shot_made::int)::numeric / COUNT(*) AS fgp3,

  SUM(nba_3_range::int) AS fga3_nba_range,
  SUM(nba_3_range::int * shot_made::int) AS fgm3_nba_range,
  SUM(nba_3_range::int * shot_made::int)::numeric / NULLIF(SUM(nba_3_range::int), 0) AS fgp3_nba_range
FROM shots_data
GROUP BY player_ncaa_id;

CREATE TABLE nba_players_from_3 AS
SELECT
  player_ncaa_id,
  COUNT(*) AS fga,
  SUM(shot_made::int) AS fgm,
  SUM(shot_made::int)::numeric / COUNT(*) AS fgp
FROM merged_shots
WHERE league_name = 'nba'
  AND shot_value = 3
  AND player_ncaa_id IS NOT NULL
GROUP BY player_ncaa_id;

CREATE TABLE ncaa_nba_3p_performance AS
SELECT
  p.player_full_name AS player,
  p.team_market AS team,
  p.number_of_seasons,
  s.fga3,
  s.fgm3,
  s.fgp3,
  s.fga3_nba_range,
  s.fgm3_nba_range,
  s.fgp3_nba_range,
  p.last_season = 2017 AS still_in_ncaa,
  CASE
    WHEN p.last_season = 2017 THEN NULL
    ELSE map.nba_id IS NOT NULL
  END AS made_nba,
  nba.fga AS fga3_in_nba,
  nba.fgm AS fgm3_in_nba,
  nba.fgp AS fgp3_in_nba
FROM ncaa_players p
  INNER JOIN ncaa_players_from_nba_3_range s ON p.player_id = s.player_ncaa_id
  LEFT JOIN players_mapping map ON p.player_id = map.ncaa_id
  LEFT JOIN nba_players_from_3 nba ON p.player_id = nba.player_ncaa_id
ORDER BY fgp3_nba_range DESC NULLS LAST;

-- NCAA who shot best from NBA 3-point range in college
SELECT
  player,
  team,
  fgp3,
  fgp3_nba_range,
  still_in_ncaa,
  fga3,
  fga3_nba_range
FROM ncaa_nba_3p_performance
WHERE fga3_nba_range >= 100
ORDER BY fgp3_nba_range DESC;

-- players with min 100 3PA from NBA range in NCAA and 100 3PA in NBA
SELECT
  player,
  team,
  fgp3_nba_range,
  fgp3_in_nba,
  fgp3_in_nba - fgp3_nba_range AS diff,
  fga3_nba_range,
  fga3_in_nba
FROM ncaa_nba_3p_performance
WHERE fga3_nba_range >= 100
  AND fga3_in_nba >= 100
ORDER BY fgp3_nba_range DESC;
