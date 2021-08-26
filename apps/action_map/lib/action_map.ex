defmodule ActionMap do
  @moduledoc false
  @timeout 1000
  alias ActionMap.Server

  def server_process(name) do
    ActionMap.Utils.list_nodes(name)
    |> Stream.map(fn node_name ->
      :rpc.call(node_name, Server, :new_process, [name], @timeout)
    end)
    |> Enum.find(fn result ->
      case result do
        {:badrpc, :nodedown} -> false
        {:badrpc, _} -> false
        _ -> true
      end
    end)
  end

  def action(pid, key) do
    GenServer.call(pid, {:action, key})
  end

  def add_action(pid, key, value) do
    GenServer.call(pid, {:add_action, key, value})
  end

  def delete_action(pid, key) do
    GenServer.call(pid, {:delete_action, key})
  end

  def update_action(pid, key, new_value) do
    GenServer.call(pid, {:update_action, key, new_value})
  end
end
