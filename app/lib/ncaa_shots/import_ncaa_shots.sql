CREATE TABLE ncaa_shots (
  game_id text,
  load_timestamp timestamp without time zone,
  season int,
  status text,
  scheduled_date timestamp without time zone,
  venue_id text,
  venue_name text,
  venue_city text,
  venue_state text,
  venue_address text,
  venue_zip text,
  venue_country text,
  venue_capacity int,
  attendance int,
  neutral_site boolean,
  conference_game boolean,
  tournament text,
  tournament_type text,
  round text,
  game_no text,
  away_market text,
  away_name text,
  away_id text,
  away_alias text,
  away_conf_name text,
  away_conf_alias text,
  away_division_name text,
  away_division_alias text,
  away_league_name text,
  home_market text,
  home_name text,
  home_id text,
  home_alias text,
  home_conf_name text,
  home_conf_alias text,
  home_division_name text,
  home_division_alias text,
  home_league_name text,
  period int,
  game_clock text,
  elapsed_time_sec int,
  possession_arrow text,
  team_name text,
  team_market text,
  team_id text,
  team_alias text,
  team_conf_name text,
  team_conf_alias text,
  team_division_name text,
  team_division_alias text,
  team_league_name text,
  team_basket text,
  possession_team_id text,
  player_id text,
  player_full_name text,
  jersey_num int,
  event_id text,
  timestamp timestamp without time zone,
  event_description text,
  event_coord_x int,
  event_coord_y int,
  event_type text,
  type text,
  shot_made boolean,
  shot_type text,
  shot_subtype text,
  three_point_shot boolean,
  points_scored text,
  turnover_type text,
  rebound_type text,
  timeout_duration text
);

\copy ncaa_shots FROM 'data/ncaa_shots.csv' CSV HEADER;

-- convert NCAA shots from full-court to half-court
UPDATE ncaa_shots
SET event_coord_x = (94 * 12) - event_coord_x,
    event_coord_y = (50 * 12) - event_coord_y,
    team_basket = 'left'
WHERE team_basket = 'right';

VACUUM FULL ANALYZE ncaa_shots;

CREATE TABLE ncaa_players AS
WITH player_aggregates AS (
  SELECT
    player_id,
    COUNT(DISTINCT season) AS number_of_seasons,
    MIN(season) AS first_season,
    MAX(season) AS last_season,
    COUNT(*) AS shots_count
  FROM ncaa_shots
  GROUP BY player_id
),
player_names AS (
  SELECT DISTINCT ON (player_id)
    player_id,
    player_full_name,
    team_market,
    team_name
  FROM ncaa_shots
  ORDER BY player_id, timestamp DESC
)
SELECT
  n.*,
  a.number_of_seasons,
  a.first_season,
  a.last_season,
  a.shots_count
FROM player_aggregates a, player_names n
WHERE a.player_id = n.player_id
ORDER BY LOWER(n.player_full_name);
CREATE UNIQUE INDEX ON ncaa_players (player_id);

CREATE TABLE players_mapping (
  nba_id integer primary key,
  ncaa_id text
);
CREATE UNIQUE INDEX ON players_mapping (ncaa_id);

\copy players_mapping FROM 'players_mapping.csv' CSV HEADER;
