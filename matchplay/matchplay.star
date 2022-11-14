load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def render_header(matchName):
    max_string_len = 14
    return [render.Box(color="#C74B00", height=7, width=64, child=render.Text(matchName[0:max_string_len]))]

def process_standings_json(standings_json,match_type,total_scores):

    scores = standings_json
    if len(scores) < int(total_scores):
      num_scores = len(scores)
    else:
      num_scores = int(total_scores)
    top = sorted(scores, key= lambda x: x["position"])[0:num_scores]
    max_string_len = 12
    top_scores = []
    for player in top:
      if len(player["name"].split()) > 1:
        player_name = player["name"].split()[0]
      else:
        player_name = player["name"]
      if match_type == "series":
        if player.get("points_adj") != None:
          point_key = "points_adj"
        else:
          point_key = "points"
      else:
        point_key = "custom_count"
      spaces = max_string_len - len(player_name) - len(str(int(player[point_key])))
      top_scores.append("{}{}{}".format(player_name, " " * spaces, int(player[point_key])))
    return "\r\n".join(top_scores)

def get_schema():
  match_options = [
    schema.Option(
      display = "Series",
      value = "series",
    ),
    schema.Option(
      display = "Tournament",
      value = "tournaments",
    ),
  ]
 
  player_count_options = []
  for x in range(3,100):
    player_count_options.append(
      schema.Option(
        display = str(x),
        value = str(x),
      )
    )

  return schema.Schema(
    version = "1",
    fields = [
      schema.Text(
        id = "ID",
        name = "ID",
        desc = "series or tournament ID",
        icon = "link",
        default = "2252",
      ),
      schema.Dropdown(
        id = "matchType",
        name = "Match Type",
        desc = "Is this a tournament or series.",
        icon = "trophy",
        default = match_options[0].value,
        options = match_options,
      ),
      schema.Dropdown(
        id = "playerCount",
        name = "Player Count",
        desc = "How many players to display",
        icon = "person",
        default = "10",
        options = player_count_options,
      ) 
    ],
  )


def main(config):

  SERIES_ID = "2252"
  STANDINGS_API_URL = "https://matchplay.events/data/{}/{}/standings".format(config.str("matchType"),config.str("ID"))
  MATCHINFO_URL = "https://matchplay.events/data/{}/{}".format(config.str("matchType"),config.str("ID"))
  FAILED_PLAYER = [{'position': 0, 'name': "sadface", "points": 0, "custom_count" : 0}]
  FAILED_HEADER = "something is wrong"

  scores_resp = http.get(STANDINGS_API_URL)
  if scores_resp.status_code != 200:
    print("Matchplay API request failed with status %d", scores_resp.status_code)
    standings = FAILED_PLAYER
  else:
    if config.str("matchType") == "series":
      standings = scores_resp.json()['overall']
    else:
      standings = scores_resp.json()
  
  match_resp = http.get(MATCHINFO_URL)
  if match_resp.status_code != 200:
    print("Matchplay API request failed with status %d", match_resp.status_code)
    match_name = FAILED_HEADER
  else:
    match_name = match_resp.json()['name']
  
  return render.Root(delay = 150,
    child = render.Column( children = [
      render.Row(children = render_header(match_name)),
      render.Row(children = [
        render.Marquee(
          width=64,
          height=32,
          scroll_direction='vertical',
          child = render.WrappedText(font="5x8", content=process_standings_json(standings,config.str("matchType"),config.str("playerCount")))
        )]
      )
    ])
  )

