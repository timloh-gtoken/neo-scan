use Mix.Config

config :neoscan_node,
  notification_seeds: [
    "http://testnotifications.neeeo.org/v1",
    "http://testnotifications.neeeo.org/v1",
    "http://testnotifications.neeeo.org/v1",
    "http://testnotifications.neeeo.org/v1",
    "http://testnotifications.neeeo.org/v1"
  ]


config :neoscan_node, start_notifications: 0

config :neoscan_node,
  seeds: [
    "http://api.otcgo.cn:20332",
    "https://seed1.neo.org:20331",
    "http://seed2.neo.org:20332",
    "http://seed3.neo.org:20332",
    "http://seed4.neo.org:20332",
    # "http://seed5.neo.org:20332",
    "http://test1.cityofzion.io:8880",
    "http://test2.cityofzion.io:8880",
    "http://test3.cityofzion.io:8880",
    "http://test4.cityofzion.io:8880",
    "http://test5.cityofzion.io:8880"
  ]

if Mix.env() == :test do
  config :neoscan_node,
    seeds: [
      "http://test1.cityofzion.io:8880",
      "http://test2.cityofzion.io:8880",
      "http://test3.cityofzion.io:8880",
      "http://test4.cityofzion.io:8880",
      "http://test5.cityofzion.io:8880"
    ]
end
