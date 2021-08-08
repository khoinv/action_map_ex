defmodule ActionMap.FileStorageTest do
  use ExUnit.Case

  alias ActionMap.FileStorage

  @moduletag :capture_log

  doctest FileStorage

  describe "get/1" do
    test "returns empty map for non_exist_key" do
      assert %{} = FileStorage.get("non_exist_key")
    end
  end

  describe "store/1" do
    test "get correct the stored data" do
      example_map = %{"a" => 1, "b" => 2}
      FileStorage.store("example", example_map)

      assert example_map = FileStorage.get("example")
      FileStorage.delete("example")
      # ensure delete is actually called
      FileStorage.get("example")
    end
  end
end
