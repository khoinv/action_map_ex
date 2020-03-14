defmodule ActionMap.FileStorageTest do
  use ExUnit.Case

  alias ActionMap.FileStorage

  @moduletag :capture_log

  doctest FileStorage

  setup do
    {:ok, pid} = FileStorage.start_link(%{})
    %{pid: pid}
  end

  describe "get/2" do
    test "returns empty map for non_exist_key", %{pid: pid} do
      assert %{} = FileStorage.get(pid, "non_exist_key")
    end
  end

  describe "store/2" do
    test "get correct the stored data", %{pid: pid} do
      example_map = %{"a" => 1, "b" => 2}
      FileStorage.store(pid, "example", example_map)

      assert example_map = FileStorage.get(pid, "example")
    end
  end
end
