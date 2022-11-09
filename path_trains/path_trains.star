load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("encoding/json.star", "json")
load("render.star", "render")
load("time.star", "time")

SOURCE_STATION = "grove_street"
API_URL = "https://path.api.razza.dev/v1/stations/{}/realtime".format(SOURCE_STATION)
DIRECTIONS = ("TO_NY")
NICE_ROUTE_DICT = {"33rd Street": "33rd",
                   "World Trade Center": "WTC",
                   "Hoboken": "Hoboken",
                   "33rd Street via Hoboken": "33-HOB",
                   "Journal Square via Hoboken": "JSQ-HOB",
                   "Journal Square": "JSQ",
                   "Newark": "Newark"
                   }


def render_flashing_circle(color):
    
    colors = {"green": "#4CBB17", "red": "#C70039"}
    return render.Animation(children=[render.Circle(color=colors[color], diameter=7),render.Circle(color="#000000", diameter=7)])

def render_header():

    return [render.Box(color="#1A48B4", height=6, width=64, child=render.Text("-----PATH---->"))]

def render_footer():

    timezone = "America/New_York"
    now = time.now().in_location(timezone)
    return [render.Text(content = now.format("3:04"),color="#1A48B4"),render.Text(content="@grove",color="#1A48B4")]

def process_schedule_json(schedule_json):

    stops = [x for x in schedule_json['upcomingTrains'] if x['direction'] in DIRECTIONS]
    return_me = []
    stop_rows = []
    time_rows = []
    for stop in stops:
        time_to_go = time.time(stop["projectedArrival"]) - time.now()
        stop_rows.append(render.Row([render.Text(font="5x8", content="{} ".format(NICE_ROUTE_DICT[stop['headsign']]))]))
        if time_to_go.seconds() < 60:
          time_left = "<1m "
        else:
          time_left = "{}m ".format(str(int(time_to_go.minutes())))
        if stop["status"] != "ARRIVING_NOW":
          time_rows.append(render.Row([render.Text(font="5x8", content=time_left)]))
        else:
          flashing = [render.Text(font="5x8", content=time_left)]
          flashing.append(render_flashing_circle("green"))
          time_rows.append(render.Row(flashing))
    return_me.append(render.Column(children=stop_rows)) 
    return_me.append(render.Column(children=time_rows)) 
    return return_me

def main():
    schedule_cached = cache.get("schedule")
    if schedule_cached != None:
        print("Hit! Displaying cached data.")
        schedule = json.loads(schedule_cached)
    else:
        print("Miss! Calling PATH API.")
        resp = http.get(API_URL)
        if resp.status_code != 200:
            fail("PATH API request failed with status %d", resp.status_code)
        schedule = resp.json()
        cache.set("schedule", str(schedule), ttl_seconds=30)

    return render.Root(delay = 1000, child = render.Stack(
        children= [
          render.Column(
            main_align = "start",  # header
            expanded = True,
            children = [
              # row to hold text with equal space between them
              render.Row(
                main_align = "space_between",
                expanded = True,
                children = render_header()
              )
            ],
          ),
          render.Column(
            main_align = "center",  # middle
            expanded = True,
            children = [
              # row to hold text with equal space between them
              render.Row(
                expanded = True,
                children = process_schedule_json(schedule)
              )
            ],
          ),
          render.Column(
            main_align = "end",  # footer
            expanded = True,
            children = [
              # row to hold text with equal space between them
              render.Row(
                main_align = "space_between",
                expanded = True,
                children = render_footer()
              )
            ],
          )
        ]
      )
    )
