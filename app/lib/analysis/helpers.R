con = dbConnect(
  dbDriver("PostgreSQL"),
  dbname = "nba-shots-db_development",
  host = "localhost"
)

query = function(sql) {
  dbSendQuery(con, sql) %>%
    fetch(n = 1e8) %>%
    as_data_frame()
}

court_bg_color = "#000004"
court_lines_color = "#999999"

circle_points = function(center = c(0, 0), radius = 1, npoints = 360) {
  angles = seq(0, 2 * pi, length.out = npoints)

  data_frame(
    x = center[1] + radius * cos(angles),
    y = center[2] + radius * sin(angles)
  )
}

font_family = "Open Sans"
title_font_family = "Fjalla One"

nba_hex = "#de1633"
ncaa_hex = "#005eb8"

theme_tws = function(base_size = 12) {
  bg_color = "#f4f4f4"
  bg_rect = element_rect(fill = bg_color, color = bg_color)

  theme_bw(base_size) +
    theme(
      text = element_text(family = font_family),
      plot.title = element_text(family = title_font_family),
      plot.subtitle = element_text(size = rel(0.7), lineheight = 1),
      plot.caption = element_text(size = rel(0.5), margin = unit(c(1, 0, 0, 0), "lines"), lineheight = 1.1, color = "#555555"),
      plot.background = bg_rect,
      axis.ticks = element_blank(),
      axis.text.x = element_text(size = rel(1)),
      axis.title.x = element_text(size = rel(1), margin = margin(1, 0, 0, 0, unit = "lines")),
      axis.text.y = element_text(size = rel(1)),
      axis.title.y = element_text(size = rel(1)),
      panel.background = bg_rect,
      panel.border = element_blank(),
      panel.grid.major = element_line(color = "grey80", size = 0.25),
      panel.grid.minor = element_line(color = "grey80", size = 0.25),
      panel.spacing = unit(1.25, "lines"),
      legend.background = bg_rect,
      legend.key.width = unit(1.5, "line"),
      legend.key = element_blank(),
      strip.background = element_blank()
    )
}

no_axis_titles = function() {
  theme(axis.title = element_blank())
}

theme_court = function(base_size = 12) {
  theme_bw(base_size) +
    theme(
      text = element_text(color = "#f0f0f0", family = font_family),
      plot.background = element_rect(fill = court_bg_color, color = court_bg_color),
      panel.background = element_rect(fill = court_bg_color, color = court_bg_color),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      axis.ticks.length = unit(0, "lines"),
      legend.background = element_rect(fill = court_bg_color, color = court_bg_color),
      legend.position = "bottom",
      legend.key = element_blank(),
      legend.text = element_text(size = rel(1.0))
    )
}
