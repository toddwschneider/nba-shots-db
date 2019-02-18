# NBA Shots DB

Rails app to populate a PostgreSQL database containing every shot attempted in the NBA since 1996.

Blog post with some analysis of the data: https://toddwschneider.com/posts/nba-vs-ncaa-basketball-shooting-performance/

Data comes from the [NBA Stats API](https://stats.nba.com/). As of March 2018, the database contains ~4.5 million shots from 2,000 players, and takes up 1.5 GB disk space. Database also includes player/season aggregates segmented by shot distance and the distance of the closest defender at the time of the shot. Closest defender info is not available for individual shots, but the aggregates are available in the `closest_defender_aggregates` table.

## NCAA men's college basketball data

NCAA data is available via [Sportradar on Google BigQuery](https://console.cloud.google.com/launcher/details/ncaa-bb-public/ncaa-basketball). The `mbb_pbp_sr` table contains men's basketball shot chart data since 2013.

The [app/lib/ncaa_shots](app/lib/ncaa_shots/) subfolder of this repo contains additional scripts to process the NCAA shots data and merge it with the NBA data, [see here for more info](app/lib/ncaa_shots).

## Setup

Assumes you have [Ruby](https://www.ruby-lang.org/en/documentation/installation/) and [PostgreSQL](https://wiki.postgresql.org/wiki/Detailed_installation_guides) installed

```
git clone git@github.com:toddwschneider/nba-shots-db.git
cd nba-shots-db/
bundle exec rake db:setup
```

## Usage

Import all available data (will take a few hours):

```
bundle exec rake import_all_shots
bundle exec rake jobs:work
```

Alternatively, import data selectively by going into the Rails console and running, e.g.:

```rb
lebron = Player.find_by(display_name: "LeBron James")
lebron.create_shots(season: "2017-18", season_type: "Regular Season")
Delayed::Worker.new.work_off
```

or

```rb
ClosestDefenderAggregate.create_by(
  season: "2017-18",
  season_type: "Regular Season",
  shot_distance_range: "17-18",
  closest_defender_range: "2-4 Feet - Tight"
)
Delayed::Worker.new.work_off
```

## Notes

- `player#create_shots` uses Postgres's `COPY` command instead of Rails's `#create` method because `COPY` is ~10x faster
- Shots have no natural unique identifier: no external IDs, no guarantee that there's only 1 shot from 1 player at the same second of the same game, etc. Accordingly, `player#create_shots` deletes and replaces data every time it is run.

## See also

### BallR: Interactive Shot Charts with R and Shiny

https://github.com/toddwschneider/ballr

The BallR shot chart app hits the NBA Stats API directly. In the future, it might make sense to expose an API interface from NBA Shots DB, then have BallR use that API instead of the NBA Stats API. In that world, BallR would be able to support more advanced options like career-long charts, team-level shot charts, etc.

BallR also has a [college edition](https://github.com/toddwschneider/ballr/tree/college) that uses the Sportradar data to make college basketball shot charts.

[![ballr](https://cloud.githubusercontent.com/assets/70271/13547819/b74dca58-e2ae-11e5-8f00-7c3c768e77e3.png)](https://github.com/toddwschneider/ballr)
