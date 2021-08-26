defmodule ActionMapTest do
  use ExUnit.Case, async: true
  alias ActionMap.FileStorage

  @moduletag :capture_log
  doctest ActionMap

  @file_name "replication"

  setup do
    LocalCluster.start_nodes("test-replication", 5, files: [__ENV__.file])

    for node <- list_all_nodes() do
      {_results, []} = :rpc.multicall(ActionMap.HashRing, :add_node, [node], 1000)
    end

    on_exit(fn ->
      :rpc.multicall(list_responsible_nodes(), FileStorage, :delete, [@file_name], 1000)
      :ok
    end)
  end

  describe "replication and partition" do
    test "the process are replicated only in replicas nodes" do
      {:ok, pid} = ActionMap.server_process(@file_name)
      :ok = ActionMap.add_action(pid, "like", "👍")

      assert_nodes_execute_results(
        list_responsible_nodes(),
        FileStorage,
        :get,
        [@file_name],
        {:ok, %{"like" => "👍"}}
      )

      assert_nodes_execute_results(
        list_all_nodes() -- list_responsible_nodes(),
        FileStorage,
        :get,
        [@file_name],
        {:error, :enoent}
      )
    end

    test "the primary process only existed in a one partition" do
      {:ok, primary_node} = ActionMap.HashRing.find_node(@file_name)

      caller = self()

      for {nodes, local_process_alive?} <- [
            {[primary_node], true},
            {list_all_nodes() -- [primary_node], false}
          ] do
        for node <- nodes do
          Node.spawn(node, fn ->
            {:ok, pid} = ActionMap.server_process(@file_name)

            alive? =
              try do
                Process.alive?(pid)
              rescue
                ArgumentError -> false
              end

            send(caller, alive?)
          end)

          assert_receive(^local_process_alive?)
        end
      end
    end
  end

  defp build_nodes_expect_results(nodes, one_node_result) do
    nodes |> Enum.map(fn _node -> one_node_result end)
  end

  def assert_nodes_execute_results(nodes, m, func, args, one_node_result) do
    nodes_expected_results = build_nodes_expect_results(nodes, one_node_result)

    assert {^nodes_expected_results, []} = :rpc.multicall(nodes, m, func, args, 100)
  end

  defp list_all_nodes(), do: Node.list([:this, :visible])

  defp list_responsible_nodes() do
    {:ok, responsible_nodes} = ActionMap.HashRing.find_nodes(@file_name)

    responsible_nodes
  end
end
