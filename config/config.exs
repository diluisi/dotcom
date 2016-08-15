# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :stations,
  base_url: {:system, "STATION_URL", "http://mbta-station-info-dev.us-east-1.elasticbeanstalk.com"}

config :v3_api,
  base_url: {:system, "V3_URL", "http://mbta-api-dev.us-east-1.elasticbeanstalk.com"}

# By default, the umbrella project as well as each child
# application will require this configuration file, ensuring
# they all use the same configuration. While one could
# configure all applications here, we prefer to delegate
# back to each application for organization purposes.
import_config "../apps/*/config/config.exs"

# Sample configuration (overrides the imported configuration above):
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
