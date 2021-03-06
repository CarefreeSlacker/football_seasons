defmodule FootballSeasonsWeb.ApiRouter do
  @moduledoc """

  ## Handle API requests.

  # Common description

  Allow to fetch all games or search games by division and/or season.
  Support JSON and Protobuf protocols.
  It's project working horse. Handling payload.
  Exercise have been minimalistic and was not restricted.
  So i decided to show you trick i have used during solving some problem during my past job.
  My purpose was providing better performance API. To achieve that I have used Mnesia <-> Plug schema.
  Reading\\Writing to HDD is slowest process through all PC activity. Because it's the last moving part.
  So moving all data to RAM will increase searching velocity. That's why i have chosen Mnesia as caching system.
  The additional trade-offs is agility for using. We could increase complexity of the requests we might design.
  Mnesia provides solid query language allowing to design complicated requests.

  But it's just my hypothesis to verify it we must measure.
  Except solving exercise this module gonna demonstrate my my skill: Load testing.

  Yes it's little bit wrong but that module have three purposes for existing:
  1. Handle requests;
  2. Compare requests speed between database and cache system;
  3. Demonstrate performance testing skill.
  But it's not open source solution. It's my test exercise. In real world i will put there only Requests documentation.
  And there will be only one type of request. With Mnesia data source.

  So there are three types of requests:

  1. Workload;
  2. Same as Workload tests but fetching data from Postgres Database;
  3. Technical for providing `protobuf` protocol deserialization.

  # API documentation

  Accept all requests without any authorization. Could return `JSON` or `Protobuf` values. Provide Protobuf schema.
  In development mode uses `4001` port by default. Configured in :football_seasons -> :plug_configuration -> :api_port.

  ## Request ALL games

  ### API with Mnesia caching

  Request `GET /api/seasons`. Accept params as get params. For example `GET /api/seasons?protocol=protobuf`.
  Accepted GET parameters:

  1. `protocol` - Optional. Response serialization protocol. Allowed values: 'protobuf', 'json'.

  Return all games in requested format `JSON` by default. Support two serialization protocols: `JSON`, `Protobuf`.
  Protobuf schema is provided by different request `GET /api/seasons/schema`. Fetch data from Mnesia.

  Params send as GET parameter. For example

  #### JSON response demonstration

  **->** `GET /api/seasons`

  **<-**

  ```
  [
    {
      "away_team_name":"Essex",
      "date":"2014-01-01",
      "division":"SP1",
      "ftag":7,
      "fthg":10,
      "ftr":"home",
      "home_team_name":"Cowex",
      "htag":7,
      "hthg":6,
      "htr":"away",
      "season":"201920",
    },
    {
      "away_team_name":"Eibar",
      "date":"2016-08-19",
      "division":"SP1",
      "ftag":1,
      "fthg":2,
      "ftr":"home",
      "home_team_name":"La Coruna",
      "htag":0,
      "hthg":0,
      "htr":"draw",
      "season":"201617",
    }
  ]
  ```

  #### Protobuf response demonstration

  **->** `GET /api/seasons?protocol=protobuf`

  **<-**

  ```
  <Binary encoded>
  ```

  ### API with Postgres database

  Return all games in requested format `JSON` by default. Support two serialization protocols: `JSON`, `Protobuf`.
  Fetch data from Postgres.

  Request `GET /api/db_seasons`. Accept params as get params.
  Accepted GET parameters:

  1. `protocol` - Optional. Response serialization protocol. Allowed values: 'protobuf', 'json'.

  #### JSON response demonstration

  **->** `GET /api/db_seasons`

  **<-**

  ```
  [
    {
      "away_team_name":"Essex",
      "date":"2014-01-01",
      "division":"SP1",
      "ftag":7,
      "fthg":10,
      "ftr":"home",
      "home_team_name":"Cowex",
      "htag":7,
      "hthg":6,
      "htr":"away",
      "season":"201920",
    },
    {
      "away_team_name":"Eibar",
      "date":"2016-08-19",
      "division":"SP2",
      "ftag":1,
      "fthg":2,
      "ftr":"home",
      "home_team_name":"La Coruna",
      "htag":0,
      "hthg":0,
      "htr":"draw",
      "season":"201617",
    }
  ]
  ```

  As you see - the same. The same result for `Protobuf` protocol. This is the point. **No difference**. Except
  fetching data method. Here every request perform database request and serialize each record to `JSON` object.
  Or to `Protobuf`.

  This API added to demonstrate requests processing speed.

  ```
  12:20:14.033 [debug] GET /api/db_seasons                              # <= Request to this API.
  12:20:14.057 [debug] QUERY OK source="games" <...> "games" AS g0 []   # <= Here is request to database
  12:20:14.092 [debug] Sent 200 in 59ms                                 # <= Postgres request speed
  12:20:21.433 [debug] GET /api/seasons                                 # <= Request to cached version. To database requests
  12:20:21.436 [debug] Sent 200 in 2ms                                  # <= Mnesia request speed
  ```

  As you see time ~30 (59 ms and 2 ms approximately) times faster.

  ### Performance testing

  In this section we gonna compare two API versions with Postgres and Mnesia using k6 load testing tool.
  Besides that we gonna compare JSON and Protobuf output data size.

  First install https://github.com/loadimpact/k6. Then you can run scripts in `performance_testing/` folder.

  #### Measure Postgres API throughput

  Run testing script for API with Postgres. Params `--rps` and `--vus` means "requests per second"
  and "virtual users" accordingly.

  ```
  $> k6 run --duration 30s --rps 2000 --vus 300 performance_testing/simple_api_testing.js
  ```

  **->**

  ```
  data_received..............: 610 MB 20 MB/s
  data_sent..................: 494 kB 16 kB/s
  <...>
  http_reqs..................: 5960   198.66376/s
  iteration_duration.........: avg=1.41s    min=123.29ms med=262.04ms max=5.47s   p(90)=4.13s    p(95)=4.4s
  iterations.................: 5195   173.166286/s # <= Here is important metric. ~173 requests per second.
  ```

  This is what does logs looks like:

  ```
  12:42:26.179 [debug] GET /api/db_seasons
  12:42:26.191 [debug] Sent 200 in 51ms
  12:42:26.199 [debug] QUERY OK source="games" db=19.2ms decode=0.1ms queue=0.1ms
  SELECT g0."id", g0."division", g0."season", g0."date", g0."home_team_id", g0."away_team_id", g0."fthg", g0."ftag", g0."hthg", g0."htag", g0."inserted_at", g0."updated_at" FROM "games" AS g0 []
  12:42:26.199 [debug] GET /api/db_seasons
  12:42:26.208 [debug] Sent 200 in 48ms
  12:42:26.216 [debug] QUERY OK source="games" db=16.6ms
  SELECT g0."id", g0."division", g0."season", g0."date", g0."home_team_id", g0."away_team_id", g0."fthg", g0."ftag", g0."hthg", g0."htag", g0."inserted_at", g0."updated_at" FROM "games" AS g0 []
  12:42:26.219 [debug] GET /api/db_seasons
  12:42:26.232 [debug] Sent 200 in 53ms
  12:42:26.237 [debug] QUERY OK source="games" db=17.5ms
  SELECT g0."id", g0."division", g0."season", g0."date", g0."home_team_id", g0."away_team_id", g0."fthg", g0."ftag", g0."hthg", g0."htag", g0."inserted_at", g0."updated_at" FROM "games" AS g0 []
  12:42:26.239 [debug] GET /api/db_seasons
  12:42:26.244 [debug] Sent 200 in 45ms
  ```

  During load testing you can look at logs. There will be a lot of errors. But project still working under pressure.
  Process some part of requests. With delay. Soft realtime (tm).

  #### Measure Mnesia API throughput

  Run load test for API with Mnesia.

  ```
  $> k6 run --duration 30s --rps 2000 --vus 300 performance_testing/fast_api_testing.js
  ```

  **->**

  ```
  data_received..............: 16 GB  521 MB/s      # <= Please remember this metric. We gonna compare it soon.
  data_sent..................: 3.4 MB 115 kB/s
  <...>
  http_reqs..................: 37464  1248.790745/s
  iteration_duration.........: avg=238.52ms min=4.39ms   med=217.81ms max=772.55ms p(90)=369.28ms p(95)=420.81ms
  iterations.................: 37464  1248.790745/s # <= As you see iterations amount increased ~7 times.
                                                    #    And it's first algorithm version without any optimisations.
  ```

  This is what does logs looks like:

  ```
  12:31:27.628 [debug] Sent 200 in 40ms
  12:31:27.631 [debug] Sent 200 in 43ms
  12:31:27.632 [debug] Sent 200 in 12ms
  12:31:27.632 [debug] Sent 200 in 44ms
  12:31:27.641 [debug] Sent 200 in 46ms
  12:31:27.641 [debug] Sent 200 in 46ms
  12:31:27.641 [debug] Sent 200 in 12ms
  ```

  #### Compare JSON and Protobuf traffic measurements

  This test send same requests as previous except it have get GET parameter `?protocol=protobuf`.

  ```
  $> k6 run --duration 30s --rps 2000 --vus 300 performance_testing/protobuf_fast_api_testing.js
  ```

  **->**

  ```
  data_received..............: 8.0 GB 268 MB/s          # <= This metric means total received traffic and it's twice less.
  data_sent..................: 5.8 MB 192 kB/s
  <...>
  http_reqs..................: 52295  1743.163497/s
  iteration_duration.........: avg=171.34ms min=8.61ms  med=158.46ms max=595.56ms p(90)=245.13ms p(95)=309.28ms
  iterations.................: 52295  1743.163497/s     # <= Iterations per seconds also increased.
  ```

  This is what does logs looks like:

  ```
  12:51:06.761 [debug] GET /api/seasons
  12:51:06.762 [debug] GET /api/seasons
  12:51:06.762 [debug] GET /api/seasons
  12:51:06.762 [debug] GET /api/seasons
  12:51:06.764 [debug] Sent 200 in 10ms
  12:51:06.768 [debug] Sent 200 in 14ms
  12:51:06.768 [debug] Sent 200 in 13ms
  12:51:06.768 [debug] GET /api/seasons
  12:51:06.769 [debug] Sent 200 in 15ms
  12:51:06.770 [debug] Sent 200 in 14ms
  12:51:06.771 [debug] Sent 200 in 17ms
  12:51:06.772 [debug] Sent 200 in 20ms
  ```

  Here we also can see request processing duration is ~3 times faster.

  ### Performance testing conclusion

  It's just first version of measurement. It's not so true because we haven't measured during long time. There our API
  might behave different. But it's good starting point for further optimisation for providing: Productivity |> Reliability |> Performance.

  Now we can conclude:

  1. Chosen request processing (Mnesia <-> Plug) schema works well
  2. Elixir\\OTP provide soft real time out of the box
  3. Project works well under big load
  4. It migh support ~1500 requests per second on my local machine(Core i7 6700, 16 GB RAM.)
  5. During measurement using `:observer.start` we found out that CPU is bottleneck. Because we have chosen mnesia
  It's necessary to perform a lot of calculations. So server must have enough powerfull CPU. Industrial CPU is ideal
  6. RAM is not big problem. But it's just short test. During endurance testing we might reveal problems
  7. Using right load testing tool it awesome https://github.com/loadimpact/k6

  ```
          /\      |‾‾|  /‾‾/  /‾/
     /\  /  \     |  |_/  /  / /
    /  \/    \    |      |  /  ‾‾\
   /          \   |  |‾\  \ | (_) |
  / __________ \  |__|  \__\ \___/ .io
  ```

  Very helpful. <3

  ## Technical API for providing `protobuf` protocol deserialization

  Protobuf schema is looks like:

  ```
  message Game {
    required string division = 1;
    required string season = 2;
    required string date = 3;
    required string home_team_name = 4;
    required string away_team_name = 5;
    required int32 hthg = 6;
    required int32 htag = 7;

    enum TeamResult {
        draw = 0;
        home = 1;
        away = 2;
    }

    required string htr = 8;
    required int32 fthg = 9;
    required int32 ftag = 10;
    required string ftr = 11;
  }
  ```

  You can get it on:

  **->** `GET /api/seasons/schema`

  **<-**

  ```
  <*.proto file>
  ```

  ## Search games by division and season

  ### Search API with Mnesia caching

  Request `GET /api/seasons/search`. Accept params as get params.
  Accepted GET parameters:

  1. `protocol` - Optional. Response serialization protocol. Allowed values: 'protobuf', 'json'.
  2. `division` - Required. Game division. String. For example: 'SP1', 'SP2', 'D1'
  3. `season` - Required. Game division. String. For example: '201718', '201819'.

  `division` and `season` parameters required. Always there is must be at least one of them. If there will be none
  response will return empty list. In case if no results also return empty list.

  Return all games in requested format `JSON` by default.

  Params send as GET parameter. For example

  #### JSON response demonstration

  **->** `GET /api/seasons/search?division=SP1&season=201617`

  **<-**

  ```
  [
    {
      "away_team_name":"Essex",
      "date":"2014-01-01",
      "division":"SP1",
      "ftag":7,
      "fthg":10,
      "ftr":"home",
      "home_team_name":"Cowex",
      "htag":7,
      "hthg":6,
      "htr":"away",
      "season":"201617",
    },
    {
      "away_team_name":"Eibar",
      "date":"2016-08-19",
      "division":"SP1",
      "ftag":1,
      "fthg":2,
      "ftr":"home",
      "home_team_name":"La Coruna",
      "htag":0,
      "hthg":0,
      "htr":"draw",
      "season":"201617",
    }
  ]
  ```

  #### Protobuf response demonstration

  **->** `GET /api/seasons/search?division=SP1&season=201617&protocol=protobuf`

  **<-**

  ```
  <Binary encoded>
  ```

  #### Logs and load testing

  Here we also gonna compare results between Mnesia and and Postgres data source. Fot that we need metadata
  from logs and load testing measurements.

  Logs looks like:

  ```
  13:39:16.440 [debug] GET /api/seasons/search
  13:39:16.442 [debug] Sent 200 in 1ms
  13:47:00.810 [debug] GET /api/seasons/search
  13:47:00.811 [debug] Sent 200 in 1ms
  ```

  Nothing unusual. Please remember request duration `1ms`. Load testing run:

  ```
  k6 run --duration 30s --rps 2000 --vus 300 performance_testing/fast_api_search_testing.js
  ```

  **->**

  ```
  data_received..............: 2.2 GB 74 MB/s       # <= If you compare size with /api/seasons you gonna see that
  data_sent..................: 7.4 MB 248 kB/s      #    it is less. Because response return only distinct
  <...>                                             #    by division and season games
  iteration_duration.........: avg=151.39ms min=5.71ms   med=149.8ms max=543.64ms p(90)=162.09ms p(95)=182.35ms
  iterations.................: 59262  1975.39572/s  # <= Almost ~2000 requests. Faster than /api/seasons.
  ```

  ### Search API with Postgres caching

  Request `GET /api/db_seasons/search`. Accept params as get params.
  Accepted GET parameters:

  1. `protocol` - Optional. Response serialization protocol. Allowed values: 'protobuf', 'json'.
  2. `division` - Required. Game division. String. For example: 'SP1', 'SP2', 'D1'
  3. `season` - Required. Game division. String. For example: '201718', '201819'.

  `division` and `season` parameters required. Always there is must be at least one of them. If there will be none
  response will return empty list. In case if no results also return empty list.

  Return all games in requested format `JSON` by default.

  Response is the same as `GET /api/seasons/search`

  #### Logs and load testing. Comparison with Mnesia version.

  Running request

  **->** `GET /api/db_seasons/search?division=SP1&season=201617`

  **<-**

  ```
  13:57:07.371 [debug] GET /api/db_seasons/search
  13:57:07.376 [debug] QUERY OK source="games" db=4.6ms queue=0.1ms
  SELECT g0."id", g0."division", g0."season", g0."date", g0."home_team_id", g0."away_team_id", g0."fthg", g0."ftag", g0."hthg", g0."htag", g0."inserted_at", g0."updated_at" FROM "games" AS g0 WHERE ((g0."division" = $1) AND (g0."season" = $2)) ["SP1", "201617"]
  13:57:07.381 [debug] Sent 200 in 9ms
  13:57:30.808 [debug] GET /api/db_seasons/search
  13:57:30.816 [debug] QUERY OK source="games" db=7.6ms queue=0.1ms
  SELECT g0."id", g0."division", g0."season", g0."date", g0."home_team_id", g0."away_team_id", g0."fthg", g0."ftag", g0."hthg", g0."htag", g0."inserted_at", g0."updated_at" FROM "games" AS g0 WHERE ((g0."division" = $1) AND (g0."season" = $2)) ["SP1", "201617"]
  13:57:30.822 [debug] Sent 200 in 14ms
  ```

  We can notice that postgres database requests added. And request duration `9, 14 ms`. It's ~12 times slower than cached Mnesia version.

  And finally run load test:

  ```
  $> k6 run --duration 30s --rps 2000 --vus 300 performance_testing/simple_api_search_testing.js
  ```

  **->**

  ```
  data_received..............: 481 MB 16 MB/s        # <= Less than previous example because of less requests.
  data_sent..................: 3.2 MB 105 kB/s
  <...>
  iteration_duration.........: avg=362.89ms min=8.48ms med=330.99ms max=1.56s   p(90)=539.1ms  p(95)=611.03ms
  iterations.................: 24603  820.098239/s   # <= Compare to /api/seasons/search ~2.5 times slower.
  ```

  And we see significant difference between Mnesia and Postgres version Q.E.D.
  """

  alias FootballSeasons.Caching.SearchSeasons
  alias FootballSeasons.Seasons
  use Plug.Router

  plug(Plug.Logger, log: :debug)
  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  get "/api/seasons" do
    {response_conn, status, body} = SearchSeasons.make_index_response(conn)
    send_resp(response_conn, status, body)
  end

  get "/api/seasons/schema" do
    file_path =
      Application.get_env(:football_seasons, :plug_configuration)[:proto_path]
      |> Path.expand(File.cwd!())

    send_file(conn, 200, file_path)
  end

  # This callback added to compare velocity between requests to cache and database
  # In fact most time spent in Jason.encode!() anyway in Mnesia we have cached JSON view
  get "/api/db_seasons" do
    games =
      Seasons.list_games()
      |> prepare_database_games()

    send_resp(conn, 200, games)
  end

  get "/api/seasons/search" do
    {response_conn, status, body} = SearchSeasons.make_search_response(conn)
    send_resp(response_conn, status, body)
  end

  # Also added for comparison with cached version
  get "/api/db_seasons/search" do
    games =
      conn
      |> fetch_params()
      |> Seasons.search_games()
      |> prepare_database_games()

    send_resp(conn, 200, games)
  end

  get "/api/health_check" do
    send_resp(conn, 200, "Ok")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp fetch_params(%Plug.Conn{query_params: query_params}) do
    {
      Map.get(query_params, "division", nil),
      Map.get(query_params, "season", nil)
    }
  end

  defp prepare_database_games(games) do
    games
    |> Enum.map(fn game ->
      game
      |> Map.delete(:__struct__)
      |> Map.delete(:__meta__)
      |> Map.delete(:home_team)
      |> Map.delete(:away_team)
      |> Map.delete(:id)
      |> Map.delete(:inserted_at)
      |> Map.delete(:updated_at)
    end)
    |> Jason.encode!()
  end
end
