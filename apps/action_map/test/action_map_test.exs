defmodule ActionMapTest do
  use ExUnit.Case, async: true
  alias ActionMap.FileStorage

  @moduletag :capture_log
  doctest ActionMap

  @file_name "test"
  setup do
    FileStorage.store(@file_name, %{"like" => "👍"})
    # ensure store is actually called
    {:ok, _} = FileStorage.get(@file_name)

    {:ok, pid} = ActionMap.server_process(@file_name)

    on_exit(
      pid,
      fn ->
        FileStorage.delete(@file_name)
        {:error, :enoent} = FileStorage.get(@file_name)
        # ensure delete is actually called
        :ok
      end
    )

    %{pid: pid}
  end

  describe "action" do
    test "returns :error for non_exist_action_key", %{pid: pid} do
      assert :error = ActionMap.action(pid, "non_exist_action_key")
    end

    test "returns an action correctly", %{pid: pid} do
      assert {:ok, "👍"} = ActionMap.action(pid, "like")
    end
  end

  describe "update_action" do
    test "updates existed action correctly", %{pid: pid} do
      ActionMap.add_action(pid, "like2", "🤞")
      ActionMap.update_action(pid, "like2", "(y)")
      assert {:ok, "(y)"} = ActionMap.action(pid, "like2")
    end
  end

  describe "delete_action" do
    test "deletes action action correctly", %{pid: pid} do
      ActionMap.delete_action(pid, "like3")
      assert :error = ActionMap.action(pid, "like3")
    end
  end

  describe "add_action" do
    test "adds action action correctly", %{pid: pid} do
      ActionMap.add_action(pid, "fuck", "👎")
      assert {:ok, "👎"} = ActionMap.action(pid, "fuck")
    end
  end

  describe "partition" do
    test "get the key from other nodes correctly", %{pid: _pid} do
      {:ok, pid} = ActionMap.server_process(@file_name)
      [node1] = LocalCluster.start_nodes("test-cluster", 1, files: [__ENV__.file])

      caller = self()

      Node.spawn(
        node1,
        fn -> send(caller, ActionMap.action(pid, "like")) end
      )

      assert_receive {:ok, "👍"}
    end
  end

  describe "replication" do
    test "files are replicated only in replicas nodes", %{pid: _pid} do
      test_file_name = "replication"
      {:ok, pid} = ActionMap.server_process(test_file_name)
      LocalCluster.start_nodes("test-cluster", 5, files: [__ENV__.file])

      ActionMap.add_action(pid, "like2", "🤞")

      assert_node_files(
        [Node.self() | ActionMap.Replication.replicas_nodes()],
        test_file_name,
        {:ok, %{"like2" => "🤞"}}
      )

      assert_node_files(
        Node.list() -- ActionMap.Replication.replicas_nodes(),
        test_file_name,
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
