defmodule ActionMapTest do
  use ExUnit.Case, async: true
  alias ActionMap.FileStorage
  doctest ActionMap

  @test_key "test"
  setup do
    {:ok, f} = FileStorage.start_link(%{})
    FileStorage.store(f, @test_key, %{"like" => "👍"})
    # ensure store is actually called
    FileStorage.get(f, "like")

    {:ok, pid} = ActionMap.start(make_ref(), @test_key)

    on_exit(
      pid,
      fn ->
        {:ok, f} = FileStorage.start_link(%{})
        FileStorage.delete(f, @test_key)
        FileStorage.get(f, @test_key)
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
      ActionMap.update_action(pid, "like", "(y)")
      assert {:ok, "(y)"} = ActionMap.action(pid, "like")
    end
  end

  describe "delete_action" do
    test "deletes action action correctly", %{pid: pid} do
      ActionMap.delete_action(pid, "like")
      assert :error = ActionMap.action(pid, "like")
    end
  end

  describe "add_action" do
    test "adds action action correctly", %{pid: pid} do
      ActionMap.add_action(pid, "fuck", "👎")
      assert {:ok, "👎"} = ActionMap.action(pid, "fuck")
    end
  end
end
