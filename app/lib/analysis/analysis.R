# NOTE:
#
# This file assumes you have populated the full NBA database, downloaded
# the NCAA shots data, and run the scripts in app/lib/ncaa_shots/ to populate
# the merged_shots table
#
# If you have not populated the NCAA data, or have only partially populated the
# NBA data, you might need to comment out some of the code in this file

library(tidyverse)
library(broom)
library(RPostgreSQL)
library(scales)
library(extrafont)

source("helpers.R")
source("court.R")

attempts_by_distance = query("
  SELECT
    UPPER(league_name) AS league_name,
    season,
    shot_value,
    FLOOR(shot_distance) AS distance_bucket,
    AVG(shot_distance) AS avg_shot_distance,
    COUNT(*) AS fga,
    SUM(shot_made::int) AS fgm
  FROM merged_shots
  WHERE shot_distance < 40
    AND season > 1996
  GROUP BY league_name, season, shot_value, distance_bucket
  ORDER BY league_name, season, shot_value, distance_bucket
")

fgp_by_distance = attempts_by_distance %>%
  filter(season >= 2013, season <= 2017, distance_bucket < 30) %>%
  group_by(league_name, distance_bucket) %>%
  summarize(
    total_fga = sum(fga),
    total_fgm = sum(fgm),
    avg_distance = sum(fga * avg_shot_distance) / sum(fga)
  ) %>%
  ungroup() %>%
  filter(total_fga > 1000) %>%
  mutate(fgp = total_fgm / total_fga) %>%
  ggplot(aes(x = avg_distance, y = fgp, color = league_name)) +
  geom_line(size = 1.5) +
  geom_text(
    data = data_frame(
      avg_distance = 12,
      fgp = c(0.45, 0.29),
      league_name = c("NBA", "NCAA")
    ),
    aes(label = league_name),
    size = 9
  ) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous("Shot distance in feet", minor_breaks = NULL) +
  expand_limits(y = 0) +
  ggtitle("Shooting Accuracy by Distance", "FG%, 2013–2018") +
  labs(caption = "NBA data via NBA Stats API; NCAA men's data via Sportradar on Google BigQuery\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  theme(axis.title.y = element_blank())

png("graphs/fgp_by_distance.png", width = 800, height = 800)
print(fgp_by_distance)
dev.off()

fga_by_distance = attempts_by_distance %>%
  filter(season >= 2013, season <= 2017) %>%
  group_by(league_name, distance_bucket) %>%
  summarize(
    total_fga = sum(fga),
    avg_distance = sum(fga * avg_shot_distance) / sum(fga)
  ) %>%
  ungroup() %>%
  group_by(league_name) %>%
  mutate(fga_frac = total_fga / sum(total_fga)) %>%
  filter(distance_bucket < 30) %>%
  ggplot(aes(x = avg_distance, y = fga_frac)) +
  geom_line(aes(color = league_name), size = 1.5) +
  geom_point(aes(color = league_name), size = 3) +
  geom_area(aes(fill = league_name), alpha = 0.2) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_fill_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL, breaks = c(0, 0.06, 0.12)) +
  scale_x_continuous("Shot distance in feet", minor_breaks = NULL) +
  facet_wrap(~league_name, ncol = 1) +
  expand_limits(y = c(0, 0.12)) +
  ggtitle("Shooting Frequency by Distance", "% of all shot attempts, 2013–2018") +
  labs(caption = "NBA data via NBA Stats API; NCAA men's data via Sportradar on Google BigQuery\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  theme(axis.title.y = element_blank())

png("graphs/fga_by_distance.png", width = 800, height = 800)
print(fga_by_distance)
dev.off()

twos_vs_threes = attempts_by_distance %>%
  filter(league_name == "NBA") %>%
  mutate(distance_type = case_when(
    shot_value == 2 & distance_bucket >= 16 ~ "midrange",
    shot_value == 3 ~ "three",
    TRUE ~ "other"
  )) %>%
  group_by(season, distance_type) %>%
  summarize(fga = sum(fga)) %>%
  ungroup() %>%
  group_by(season) %>%
  mutate(frac = fga / sum(fga)) %>%
  ungroup() %>%
  filter(distance_type != "other") %>%
  ggplot(aes(x = season, y = frac, color = distance_type)) +
  geom_line(size = 1.5) +
  geom_text(
    data = data_frame(
      season = 2013,
      frac = c(0.1, 0.35),
      distance_type = c("midrange", "three"),
      distance_type_label = c("Mid-range\ntwo-pointers", "Three-pointers")
    ),
    aes(label = distance_type_label),
    size = 9
  ) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous(minor_breaks = NULL) +
  expand_limits(y = c(0, 0.4)) +
  ggtitle("NBA Shot Attempts by Type", "% of all shots") +
  labs(caption = "Mid-range two-pointers = 16+ feet\nData via NBA Stats API\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  no_axis_titles()

png("graphs/twos_vs_threes.png", width = 800, height = 800)
print(twos_vs_threes)
dev.off()

mid_range_twos = attempts_by_distance %>%
  mutate(mid_range_two = case_when(
    shot_value == 2 & distance_bucket >= 16 ~ TRUE,
    TRUE ~ FALSE
  )) %>%
  group_by(league_name, season) %>%
  summarize(
    total_fga = sum(fga),
    mid_2_fga = sum(fga * as.numeric(mid_range_two))
  ) %>%
  ungroup() %>%
  mutate(mid_2_frac = mid_2_fga / total_fga) %>%
  ggplot(aes(x = season, y = mid_2_frac, color = league_name)) +
  geom_line(size = 1.5) +
  geom_text(
    data = data_frame(
      season = 2011.25,
      mid_2_frac = c(0.17, 0.06),
      league_name = c("NBA", "NCAA")
    ),
    aes(label = league_name),
    size = 9
  ) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous(minor_breaks = NULL) +
  expand_limits(y = c(0, 0.25)) +
  ggtitle("Mid-Range 2-Point Attempt Rate", "% of all shots that were 2-pointers from 16+ feet") +
  labs(caption = "NBA data via NBA Stats API; NCAA men's data via Sportradar on Google BigQuery\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  no_axis_titles()

png("graphs/mid_range_twos.png", width = 800, height = 800)
print(mid_range_twos)
dev.off()

threes = attempts_by_distance %>%
  group_by(league_name, season) %>%
  summarize(
    total_fga = sum(fga),
    three_fga = sum(fga * as.numeric(shot_value == 3))
  ) %>%
  ungroup() %>%
  mutate(three_frac = three_fga / total_fga) %>%
  ggplot(aes(x = season, y = three_frac, color = league_name)) +
  geom_line(size = 1.5) +
  geom_text(
    data = data_frame(
      season = 2014,
      three_frac = c(0.23, 0.37),
      league_name = c("NBA", "NCAA")
    ),
    aes(label = league_name),
    size = 9
  ) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous(minor_breaks = NULL) +
  expand_limits(y = c(0, 0.4)) +
  ggtitle("3-Point Attempt Rate", "% of all shots that were 3-pointers") +
  labs(caption = "NBA data via NBA Stats API; NCAA men's data via Sportradar on Google BigQuery\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  no_axis_titles()

png("graphs/threes.png", width = 800, height = 800)
print(threes)
dev.off()

three_point_fgp = attempts_by_distance %>%
  filter(shot_value == 3) %>%
  group_by(league_name, season) %>%
  summarize(
    total_fga = sum(fga),
    total_fgm = sum(fgm),
    avg_distance = sum(fga * avg_shot_distance) / sum(fga)
  ) %>%
  ungroup() %>%
  filter(total_fga > 1000) %>%
  mutate(fgp = total_fgm / total_fga) %>%
  ggplot(aes(x = season, y = fgp, color = league_name)) +
  geom_line(size = 1.5) +
  geom_text(
    data = data_frame(
      season = 2013,
      fgp = c(0.39, 0.32),
      league_name = c("NBA", "NCAA")
    ),
    aes(label = league_name),
    size = 9
  ) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous(minor_breaks = NULL) +
  expand_limits(y = 0) +
  ggtitle("3-Point Accuracy", "3-Point FG%") +
  labs(caption = "NBA data via NBA Stats API; NCAA men's data via Sportradar on Google BigQuery\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  theme(axis.title.y = element_blank())

png("graphs/three_point_fgp.png", width = 800, height = 800)
print(three_point_fgp)
dev.off()

three_point_attempts_by_location = query("
  SELECT
    UPPER(league_name) AS league_name,
    season,
    CASE
      WHEN shot_angle BETWEEN 36 AND 144 THEN 'above_the_break'
      ELSE 'corner'
    END AS location,
    COUNT(*) AS fga,
    SUM(shot_made::int) AS fgm
  FROM merged_shots
  WHERE shot_distance < 40
    AND season > 1996
    AND shot_value = 3
  GROUP BY league_name, season, location
  ORDER BY league_name, season, location
")

three_point_attempts_by_location = three_point_attempts_by_location %>%
  mutate(fgp = fgm / fga) %>%
  group_by(league_name, season) %>%
  mutate(frac_attempts = fga / sum(fga)) %>%
  ungroup()

corner_threes = three_point_attempts_by_location %>%
  filter(location == "corner") %>%
  ggplot(aes(x = season, y = frac_attempts, color = league_name)) +
  geom_line(size = 1.5) +
  geom_text(
    data = data_frame(
      season = 2011,
      frac_attempts = c(0.39, 0.29),
      league_name = c("NBA", "NCAA")
    ),
    aes(label = league_name),
    size = 9
  ) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous(minor_breaks = NULL) +
  expand_limits(y = c(0, 0.4)) +
  ggtitle("Corner 3-Point Attempts", "% of all 3-point attempts that were from corners") +
  labs(caption = "NBA data via NBA Stats API; NCAA men's data via Sportradar on Google BigQuery\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  no_axis_titles()

png("graphs/corner_3s.png", width = 800, height = 800)
print(corner_threes)
dev.off()

closest_defenders_stats = query("
  SELECT
    (string_to_array(shot_distance_range, '-'))[1]::int AS distance_bucket,
    LOWER((string_to_array(closest_defender_range, ' - '))[1]) AS defender_range,
    SUM(fgm) AS fgm,
    SUM(fga) AS fga,
    SUM(fg2m) AS fg2m,
    SUM(fg2a) AS fg2a,
    SUM(fg3m) AS fg3m,
    SUM(fg3a) AS fg3a
  FROM closest_defender_aggregates
  GROUP BY distance_bucket, defender_range
  ORDER BY distance_bucket, defender_range
") %>%
  mutate(
    fgp = fgm / fga,
    defender_range = factor(
      defender_range,
      levels = c("6+ feet", "4-6 feet", "2-4 feet", "0-2 feet")
    ),
    pps = (fg2m * 2 + fg3m * 3) / fga
  )

write_csv(closest_defenders_stats, "closest_defenders_stats.csv")

closest_defenders = closest_defenders_stats %>%
  filter(fga >= 100) %>%
  ggplot(aes(x = distance_bucket + 0.5, y = fgp, color = defender_range)) +
  geom_line(size = 1.5) +
  scale_color_discrete("Closest defender") +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous("Shot distance in feet", minor_breaks = NULL) +
  expand_limits(y = c(0, 1)) +
  ggtitle("FG% by Closest Defender", "NBA 2013–2018") +
  labs(caption = "Data via NBA Stats API\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  theme(
    axis.title.y = element_blank(),
    legend.position = c(0.17, 0.17),
    legend.key.height = unit(2.2, "lines"),
    legend.key.width = unit(2.2, "lines"),
    legend.title = element_text(size = rel(0.6)),
    legend.text = element_text(size = rel(0.6))
  )

png("graphs/closest_defenders.png", width = 800, height = 800)
print(closest_defenders)
dev.off()

closest_defenders_pps = closest_defenders_stats %>%
  filter(fga >= 100) %>%
  ggplot(aes(x = distance_bucket + 0.5, y = pps, color = defender_range)) +
  geom_line(size = 1.5) +
  scale_color_discrete("Closest defender") +
  scale_y_continuous(labels = comma, minor_breaks = NULL) +
  scale_x_continuous("Shot distance in feet", minor_breaks = NULL) +
  expand_limits(y = c(0, 2)) +
  ggtitle("Points Per Shot by Closest Defender", "NBA 2013–2018") +
  labs(caption = "Data via NBA Stats API\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  theme(
    axis.title.y = element_blank(),
    legend.position = c(0.17, 0.17),
    legend.key.height = unit(2.2, "lines"),
    legend.key.width = unit(2.2, "lines"),
    legend.title = element_text(size = rel(0.6)),
    legend.text = element_text(size = rel(0.6))
  )

png("graphs/closest_defenders_pps.png", width = 800, height = 800)
print(closest_defenders_pps)
dev.off()

# most valuable shots over 20 feet
closest_defenders_stats %>%
  filter(distance_bucket >= 20) %>%
  arrange(desc(pps))

# logistic regression to compare shot accuracy for same players from last year
# in NCAA to first year in NBA
ncaa_and_nba_shots = query("
  SELECT
    s.player_nba_id,
    s.league_name,
    s.shot_distance,
    s.shot_angle,
    s.shot_value,
    s.shot_made,
    s.season,
    nba.from_year AS first_nba_season,
    ncaa.last_season AS last_ncaa_season
  FROM merged_shots s
    INNER JOIN players nba ON s.player_nba_id = nba.nba_id
    INNER JOIN ncaa_players ncaa ON s.player_ncaa_id = ncaa.player_id
  WHERE s.player_nba_id IS NOT NULL
    AND s.player_ncaa_id IS NOT NULL
    AND s.shot_distance < 30
  ORDER BY s.player_nba_id, s.season, s.attempted_on
")

regression_data = ncaa_and_nba_shots %>%
  filter(season == last_ncaa_season | season == first_nba_season) %>%
  transmute(
    player = factor(player_nba_id),
    league = factor(league_name),
    shot_distance = shot_distance,
    sqrt_dist = sqrt(shot_distance),
    distance_bucket = factor(floor(shot_distance / 3) * 3),
    shot_value = factor(shot_value),
    made = as.numeric(shot_made),
    under_6_ft = factor(shot_distance < 6),
    season = season,
    first_nba_season = first_nba_season,
    last_ncaa_season = last_ncaa_season
  )

model = glm(
  made ~ player + under_6_ft * league + distance_bucket,
  family = binomial(link = "logit"),
  data = regression_data
)

tidy(model) %>% filter(!grepl("^player", term))

#                         term   estimate  std.error  statistic       p.value
# 1                (Intercept) -0.6669336 0.16706843  -3.991979  6.552430e-05
# 2             under_6_ftTRUE  1.2259691 0.05803172  21.125845  4.603210e-99
# 3                 leaguencaa  0.1500213 0.01801535   8.327416  8.262597e-17
# 4           distance_bucket3 -0.8482049 0.02107668 -40.243755  0.000000e+00
# 5           distance_bucket6  0.3169053 0.05917938   5.354995  8.555870e-08
# 6           distance_bucket9  0.2175710 0.06078645   3.579268  3.445585e-04
# 7          distance_bucket12  0.1830482 0.06087916   3.006747  2.640599e-03
# 8          distance_bucket15  0.2487310 0.06006647   4.140929  3.459019e-05
# 9          distance_bucket18  0.3189482 0.06211006   5.135210  2.818298e-07
# 10         distance_bucket21  0.2539479 0.05743955   4.421133  9.818486e-06
# 11         distance_bucket24  0.1408085 0.05760253   2.444485  1.450592e-02
# 12 under_6_ftTRUE:leaguencaa  0.5932606 0.02749827  21.574469 3.120397e-103

model_predictions = regression_data %>%
  mutate(predicted = predict(model, type = "response"))

nba_players = query("SELECT id, nba_id, display_name FROM players")

wiggins = filter(nba_players, display_name == "Andrew Wiggins")
# nothing particular about Andrew Wiggins, just pick someone with a lot of
# shots in both datasets and an average player term to illustrate predictions

model_predictions %>%
  filter(player == wiggins$nba_id) %>%
  group_by(league, distance_bucket) %>%
  summarize(
    avg_distance = mean(shot_distance),
    predicted = mean(predicted),
    actual = mean(made),
    fga = n()
  ) %>%
  ungroup() %>%
  arrange(distance_bucket, league)

predicted_fgp_by_distance = model_predictions %>%
  filter(player == wiggins$nba_id) %>%
  group_by(league, distance_bucket) %>%
  summarize(
    avg_distance = mean(shot_distance),
    predicted = mean(predicted)
  ) %>%
  ungroup() %>%
  ggplot(aes(x = avg_distance, y = predicted, color = league)) +
  geom_line(size = 1.5) +
  geom_text(
    data = data_frame(
      avg_distance = 14,
      predicted = c(0.29, 0.45),
      league = c("nba", "ncaa"),
      label_text = c("First season in NBA", "Last season in NCAA")
    ),
    aes(label = label_text),
    size = 9
  ) +
  scale_color_manual(values = c(nba_hex, ncaa_hex), guide = FALSE) +
  scale_y_continuous(labels = percent, minor_breaks = NULL) +
  scale_x_continuous("Shot distance in feet", minor_breaks = NULL) +
  expand_limits(y = 0) +
  ggtitle(
    "Predicted Shooting Accuracy by Distance",
    "Predicted FG% for player transitioning from NCAA to NBA"
  ) +
  labs(caption = "NBA data via NBA Stats API; NCAA men's data via Sportradar on Google BigQuery\ntoddwschneider.com") +
  theme_tws(base_size = 36) +
  theme(axis.title.y = element_blank())

png("graphs/predicted_fgp_by_distance.png", width = 800, height = 800)
print(predicted_fgp_by_distance)
dev.off()

# career-long shot chart example
lebron = filter(nba_players, display_name == "LeBron James")

lebron_shots = query(paste0("
  SELECT
    location_x,
    location_y,
    CASE WHEN shot_made THEN 'made' ELSE 'missed' END AS shot_made
  FROM merged_shots
  WHERE player_nba_id = ", lebron$nba_id
))

lebron_shot_map = nba_court +
  geom_point(
    data = lebron_shots,
    aes(x = location_x, y = location_y, color = shot_made),
    alpha = 0.5,
    size = 3
  ) +
  scale_color_manual(values = c(made = "#FDE725", missed = "#1F9D89"), guide = FALSE) +
  ggtitle("LeBron James 2003–18 Shot Attempts") +
  theme_court(base_size = 60)

png("graphs/lebron_shot_map.png", width = 2000, height = 1500, bg = court_bg_color)
print(lebron_shot_map)
dev.off()

rockets_pacers_shots = query("
  SELECT
    location_x,
    location_y,
    CASE WHEN shot_made THEN 'made' ELSE 'missed' END AS shot_made,
    team_name
  FROM merged_shots
  WHERE team_name IN ('Houston Rockets', 'Indiana Pacers')
    AND league_name = 'nba'
    AND season = 2017
")

rockets_shot_map = nba_court +
  geom_point(
    data = filter(rockets_pacers_shots, team_name == "Houston Rockets"),
    aes(x = location_x, y = location_y, color = shot_made),
    alpha = 0.5,
    size = 3
  ) +
  scale_color_manual(values = c(made = "#FDE725", missed = "#1F9D89"), guide = FALSE) +
  ggtitle("Houston Rockets 2017–18 Shot Attempts") +
  theme_court(base_size = 60)

png("graphs/rockets_shot_map.png", width = 2000, height = 1500, bg = court_bg_color)
print(rockets_shot_map)
dev.off()

pacers_shot_map = nba_court +
  geom_point(
    data = filter(rockets_pacers_shots, team_name == "Indiana Pacers"),
    aes(x = location_x, y = location_y, color = shot_made),
    alpha = 0.5,
    size = 3
  ) +
  scale_color_manual(values = c(made = "#FDE725", missed = "#1F9D89"), guide = FALSE) +
  ggtitle("Indiana Pacers 2017–18 Shot Attempts") +
  theme_court(base_size = 60)

png("graphs/pacers_shot_map.png", width = 2000, height = 1500, bg = court_bg_color)
print(pacers_shot_map)
dev.off()
