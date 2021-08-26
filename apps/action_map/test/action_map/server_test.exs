defmodule ActionMap.ServerTest do
  use ExUnit.Case, async: true
  alias ActionMap.FileStorage
  alias ActionMap.Server

  @moduletag :capture_log
  doctest ActionMap

  @file_name "test"
  setup do
    {:ok, pid} = Server.new_process(@file_name)
    on_exit(fn -> FileStorage.delete(@file_name) end)

    %{pid: pid}
  end

  describe "action" do
    test "returns :error for non_exist_action_key", %{pid: pid} do
      GenServer.call(pid, {:add_action, "like", "👍"})
      assert :error = GenServer.call(pid, {:action, "non_exist_action_key"})
    end
  end

  describe "update_action" do
    test "updates existed action correctly", %{pid: pid} do
      GenServer.call(pid, {:add_action, "like2", "🤞"})
      GenServer.call(pid, {:update_action, "like2", "(y)"})
      assert {:ok, "(y)"} = GenServer.call(pid, {:action, "like2"})
    end
  end

  describe "delete_action" do
    test "deletes action action correctly", %{pid: pid} do
      GenServer.call(pid, {:delete_action, "like3"})
      assert :error = GenServer.call(pid, {:action, "like3"})
    end
  end

  describe "add_action" do
    test "adds action action correctly", %{pid: pid} do
      GenServer.call(pid, {:add_action, "fuck", "👎"})
      assert {:ok, "👎"} = GenServer.call(pid, {:action, "fuck"})
    end
  end
end
