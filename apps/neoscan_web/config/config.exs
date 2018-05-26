# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :neoscan_web,
  namespace: NeoscanWeb,
  ecto_repos: [Neoscan.Repo]

# Configures the endpoint
config :neoscan_web, NeoscanWeb.Endpoint,
  url: [host: "localhost"],
  http: [compress: true],
  render_errors: [view: NeoscanWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: NeoscanWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$date $time $metadata[$level] [$node] $message\n",
  metadata: [:request_id]

config :neoscan_web, :generators, context_app: :neoscan

config :wobserver,
  mode: :plug,
  remote_url_prefix: "/wobserver"

config :number,
  delimit: [
    precision: 0,
    delimiter: ",",
    separator: "."
  ],
  currency: [
    unit: "$",
    delimiter: ",",
    separator: "."
  ]

config :spandex,
  # required, default service name
  service: :my_api,
  # required
  adapter: Spandex.Adapters.Datadog,
  disabled?: {:system, :boolean, "DISABLE_SPANDEX", true},
  env: {:system, "APM_ENVIRONMENT", "unknown"},
  application: :neoscan_web,
  levels: [:low, :medium, :high],
  default_span_level: :low,
  level: :low,
  ignored_methods: ["OPTIONS"],
  # ignored routes accepts regexes, and strings. If it is a string it must match exactly.
  ignored_routes: [~r/health_check/, "/status"],
  # do not set the following configurations unless you are sure.
  log_traces?: false

config :spandex, :datadog,
  host: {:system, "DOCKER_HOST_IP", "localhost"},
  port: {:system, "DATADOG_PORT", 8126},
  batch_size: 10,
  sync_threshold: 20,
  services: []

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
