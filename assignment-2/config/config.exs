import Config

config :assignment,
  until: DateTime.utc_now() |> DateTime.to_unix(),
  from: (DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 33,
  rate: 5 # in n per second
