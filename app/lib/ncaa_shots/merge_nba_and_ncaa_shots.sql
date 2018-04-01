CREATE TABLE merged_shots (
  league_name text not null,
  player_nba_id integer,
  player_ncaa_id text,
  location_x numeric not null,
  location_y numeric not null,
  shot_made boolean not null,
  season integer not null,
  season_type text not null,
  attempted_on date not null,
  period integer not null,
  minutes_remaining integer,
  seconds_remaining integer,
  team_name text not null,
  shot_type text,
  shot_value integer not null,
  points_scored integer not null,
  shot_distance numeric,
  shot_angle numeric
);

INSERT INTO merged_shots (
  league_name, player_nba_id, player_ncaa_id, location_x, location_y,
  shot_made, season, season_type, attempted_on, period, minutes_remaining,
  seconds_remaining, team_name, shot_type, shot_value, points_scored
)
SELECT
  'nba',
  s.player_nba_id,
  map.ncaa_id,
  loc_x::numeric / 10,
  loc_y::numeric / 10,
  shot_made_flag::boolean,
  substr(season, 1, 4)::integer,
  season_type,
  game_date,
  period,
  minutes_remaining,
  seconds_remaining,
  team_name,
  action_type,
  CASE shot_type WHEN '3PT Field Goal' THEN 3 ELSE 2 END,
  CASE
    WHEN shot_made_flag = 0 THEN 0
    WHEN shot_made_flag = 1 AND shot_type = '3PT Field Goal' THEN 3
    ELSE 2
  END
FROM shots s
  LEFT JOIN players_mapping map ON s.player_nba_id = map.nba_id;

-- rotate NCAA (x, y) coords 90 degrees counter-clockwise and adjust so hoop is
-- centered at (0, 0), assuming that center of hoop is 5.25 feet from baseline
INSERT INTO merged_shots (
  league_name, player_nba_id, player_ncaa_id, location_x, location_y,
  shot_made, season, season_type, attempted_on, period, minutes_remaining,
  seconds_remaining, team_name, shot_type, shot_value, points_scored
)
SELECT
  'ncaa',
  map.nba_id,
  player_id,
  25 - (event_coord_y::numeric / 12),
  event_coord_x::numeric / 12 - 5.25,
  shot_made,
  season,
  coalesce(tournament, 'Regular Season'),
  timestamp::date,
  period,
  (string_to_array(game_clock, ':'))[1]::int,
  (string_to_array(game_clock, ':'))[2]::int,
  team_market || ' ' || team_name,
  shot_type,
  CASE three_point_shot WHEN true THEN 3 ELSE 2 END,
  coalesce(points_scored, '0')::int
FROM ncaa_shots s
  LEFT JOIN players_mapping map ON s.player_id = map.ncaa_id;

UPDATE merged_shots
SET shot_distance = sqrt(pow(location_x, 2) + pow(location_y, 2));

UPDATE merged_shots
SET shot_angle = acos(location_x / shot_distance) * 180 / pi()
WHERE shot_distance > 0
  AND location_x / shot_distance BETWEEN -1 AND 1;

-- remove shots that seem to be miscoded based on distances and point values
DELETE FROM merged_shots WHERE league_name = 'nba' AND shot_distance > 25 AND shot_value = 2;
DELETE FROM merged_shots WHERE league_name = 'nba' AND shot_distance < 21.5 AND shot_value = 3;
DELETE FROM merged_shots WHERE league_name = 'ncaa' AND shot_distance > 22 AND shot_value = 2;
DELETE FROM merged_shots WHERE league_name = 'ncaa' AND shot_distance < 19.5 AND shot_value = 3;

VACUUM FULL ANALYZE merged_shots;
