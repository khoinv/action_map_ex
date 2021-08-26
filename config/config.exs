# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :action_map,
  storage_path: "./priv/storage",
  # each data item is replicated in N -1 nodes(existed in N nodes)
  replicas_count: 2,
  hash_ring: %{
    # each node will map to vnodes_count
    vnodes_count: 256,
    # equal-sized partitions count
    partitions_count: 2000
  }
