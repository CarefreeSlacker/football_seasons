ExUnit.start()
Faker.start()
{:ok, _} = Application.ensure_all_started(:ex_machina)
Ecto.Adapters.SQL.Sandbox.mode(FootballSeasons.Repo, :manual)
FootballSeasons.Caching.CacheRecordService.reset_mnesia()
