:ok = LocalCluster.start()
Application.ensure_all_started(:action_map)
ExUnit.start()
