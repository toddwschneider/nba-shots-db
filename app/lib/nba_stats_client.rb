class NbaStatsClient
  SEASON_TYPES = ["Regular Season", "Playoffs"]

  CLOSEST_DEFENDER_RANGES = [
    "0-2 Feet - Very Tight",
    "2-4 Feet - Tight",
    "4-6 Feet - Open",
    "6+ Feet - Wide Open"
  ]

  MIN_YEAR = 1996
  MIN_CLOSEST_DEFENDER_YEAR = 2013

  def all_players
    params = {
      LeagueID: "00",
      Season: "2017-18",
      IsOnlyCurrentSeason: 0
    }

    get(path: "commonallplayers", params: params)
  end

  def shots(player_id:, season:, season_type: "Regular Season")
    raise "invalid season" unless all_seasons.include?(season)
    raise "invalid season type" unless season_types.include?(season_type)

    params = {
      PlayerID: player_id,
      Season: season,
      SeasonType: season_type,
      PlayerPosition: "",
      ContextMeasure: "FGA",
      DateFrom: "",
      DateTo: "",
      GameID: "",
      GameSegment: "",
      LastNGames: 0,
      LeagueID: "00",
      Location: "",
      Month: 0,
      OpponentTeamID: 0,
      Outcome: "",
      Period: 0,
      Position: "",
      RookieYear: "",
      SeasonSegment: "",
      TeamID: 0,
      VsConference: "",
      VsDivision: ""
    }

    get(path: "shotchartdetail", params: params)
  end

  def shot_stats_by_closest_defender(season:, shot_dist_range: nil, close_def_dist_range:, season_type: "Regular Season")
    if shot_dist_range.present?
      raise "As of December 2020, it appears that the shot_dist_range filter is no longer supported by the NBA API"
    end

    raise "invalid season" unless closest_defender_seasons.include?(season)
    raise "invalid season type" unless season_types.include?(season_type)
    raise "invalid defender range" unless closest_defender_ranges.include?(close_def_dist_range)

    params = {
      CloseDefDistRange: close_def_dist_range,
      ShotDistRange: shot_dist_range,
      Season: season,
      SeasonType: season_type,
      College: "",
      Conference: "",
      Country: "",
      DateFrom: "",
      DateTo: "",
      Division: "",
      DraftPick: "",
      DraftYear: "",
      DribbleRange: "",
      GameScope: "",
      GameSegment: "",
      GeneralRange: "",
      Height: "",
      LastNGames: 0,
      LeagueID: "00",
      Location: "",
      Month: 0,
      OpponentTeamID: 0,
      Outcome: "",
      PORound: 0,
      PaceAdjust: "N",
      PerMode: "Totals",
      Period: 0,
      PlayerExperience: "",
      PlayerPosition: "",
      PlusMinus: "N",
      Rank: "N",
      SeasonSegment: "",
      ShotClockRange: "",
      StarterBench: "",
      TeamID: 0,
      TouchTimeRange: "",
      VsConference: "",
      VsDivision: "",
      Weight: ""
    }

    get(path: "leaguedashplayerptshot", params: params)
  end

  def all_years
    max_year = if Date.today.month >= 10
      Date.today.year
    else
      Date.today.year - 1
    end

    MIN_YEAR..max_year
  end

  def year_to_season(year)
    "#{year}-#{(year + 1).to_s.last(2)}"
  end

  def all_seasons
    all_years.map { |y| year_to_season(y) }
  end

  def closest_defender_seasons
    all_seasons.select do |s|
      s.first(4).to_i >= MIN_CLOSEST_DEFENDER_YEAR
    end
  end

  def season_types
    SEASON_TYPES
  end

  def closest_defender_ranges
    CLOSEST_DEFENDER_RANGES
  end

  private

  BASE_URL = "https://stats.nba.com/stats/"

  REQUEST_HEADERS = {
    accept: "application/json, text/plain, */*",
    accept_language: "en-US,en;q=0.8",
    cache_control: "no-cache",
    connection: "keep-alive",
    host: "stats.nba.com",
    pragma: "no-cache",
    referer: "https://www.nba.com/",
    upgrade_insecure_requests: "1",
    user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9"
  }

  def get(path:, params: {}, timeout: 5)
    request = RestClient::Request.execute(
      method: :get,
      url: "#{BASE_URL}#{path}",
      headers: REQUEST_HEADERS.merge(params: params),
      timeout: timeout
    )

    json = JSON.parse(request.body).dig("resultSets", 0)

    row_names = json["headers"].map(&:downcase)

    json["rowSet"].map do |row|
      Hashie::Mash.new(row_names.zip(row).to_h)
    end
  end
end
