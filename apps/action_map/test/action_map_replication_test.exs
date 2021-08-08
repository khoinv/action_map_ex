defmodule ActionMapReplicationTest do
  use ExUnit.Case, async: true
  alias ActionMap.FileStorage

  @moduletag :capture_log
  doctest ActionMap

  @file_name "replication"

  describe "replication" do
    test "files are replicated only in replicas nodes" do
      {:ok, pid} = ActionMap.server_process(@file_name)
      LocalCluster.start_nodes("test-replication", 5, files: [__ENV__.file])

      ActionMap.add_action(pid, "like2", "🤞")

      assert_node_files(
        [Node.self() | ActionMap.Replication.replicas_nodes()],
        @file_name,
        {:ok, %{"like2" => "🤞"}}
      )

      assert_node_files(
        Node.list() -- ActionMap.Replication.replicas_nodes(),
        @file_name,
        {:error, :enoent}
      )
    end
  end

  defp assert_node_files(nodes, file_name, node_expect) do
    nodes_expect =
      for _node <- nodes do
        node_expect
      end

    assert {^nodes_expect, []} = :rpc.multicall(nodes, FileStorage, :get, [file_name], 1000)
  end
end
