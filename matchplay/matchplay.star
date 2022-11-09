load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("encoding/json.star", "json")
load("render.star", "render")
load("time.star", "time")

SERIES_ID = "xkyrw"
API_URL = "https://matchplay.events/data/tournaments/{}/standings".format(SERIES_ID)
TOTAL_SCORES = 17

def render_header():

    return [render.Box(color="#C74B00", height=6, width=64, child=render.Text("JC FLIPPERS"))]

def process_standings_json(standings_json,is_tournament=False):

    if is_tournament:
      scores = standings_json["overall"]
    else:
      scores = standings_json
    if len(scores) < TOTAL_SCORES:
      num_scores = scores
    else:
      num_scores = TOTAL_SCORES
    top = sorted(scores, key= lambda x: x["position"])[0:num_scores]
    max_string_len = 12
    top_scores = []
    for player in top:
      if len(player["name"].split()) > 1:
        player_name = player["name"].split()[0]
      else:
        player_name = player["name"]
      if player.get("points_adj") != None:
        point_key = "points_adj"
      else:
        point_key = "points"
      spaces = max_string_len - len(player_name) - len(str(int(player[point_key])))
      top_scores.append("{}{}{}".format(player_name, " " * spaces, int(player[point_key])))
    return "\r\n".join(top_scores)

def main():
    standings_cached = cache.get("standings")
    if standings_cached != None:
        print("Hit! Displaying cached data.")
        standings = json.loads(standings_cached)
    else:
        print("Miss! Calling Matchplay API.")
        resp = http.get(API_URL)
        if resp.status_code != 200:
            fail("Matchplay API request failed with status %d", resp.status_code)
        standings = resp.json()
        cache.set("standings", str(standings), ttl_seconds=60)

    return render.Root(delay = 100,
      child = render.Column( children = [
        render.Row(children = render_header()),
        render.Row(children = [
          render.Marquee(
            width=64,
            height=32,
            scroll_direction='vertical',
            child = render.WrappedText(font="5x8", content=process_standings_json(standings))
          )]
        )
        ])
      )
