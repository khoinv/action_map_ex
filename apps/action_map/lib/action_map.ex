defmodule ActionMap do
  @moduledoc false

  use GenServer

  defstruct file_name: nil, action_map: %{}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:global, {__MODULE__, opts[:name]}})
  end

  @impl true
  def init(opts) do
    send(self(), :real_init)
    {:ok, %__MODULE__{file_name: opts[:file_name]}}
  end

  @impl true
  def handle_info(:real_init, %{file_name: file_name} = state) do
    {:noreply, %{state | action_map: ActionMap.FileStorage.get(file_name)}}
  end

  def handle_info(:store, %{file_name: file_name, action_map: action_map} = state) do
    #    ActionMap.FileStorage.store(file_name, action_map)
    ActionMap.FileStorage.store_all_nodes(file_name, action_map)

    {:noreply, state}
  end

  @impl true
  def handle_call({:action, key}, _from, %{action_map: action_map} = state) do
    {:reply, Map.fetch(action_map, key), state}
  end

  @impl true
  def handle_cast({:add_action, key, value}, %{action_map: action_map} = state) do
    action_map = Map.put(action_map, key, value)
    send(self(), :store)
    {:noreply, %{state | action_map: action_map}}
  end

  @impl true
  def handle_cast({:update_action, key, value}, %{action_map: action_map} = state) do
    action_map = Map.put(action_map, key, value)
    send(self(), :store)
    {:noreply, %{state | action_map: action_map}}
  end

  @impl true
  def handle_cast({:delete_action, key}, %{action_map: action_map} = state) do
    action_map = Map.delete(action_map, key)
    send(self(), :store)
    {:noreply, %{state | action_map: action_map}}
  end

  # Api

  ### NOTE :global module performs a synchronized chat across the entire cluster
  defp new_process(name) do
    case DynamicSupervisor.start_child(
           ActionMap.Supervisor,
           {__MODULE__, [file_name: name, name: name]}
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @doc """
    NOTE: :global.whereis_name/1 doesn't lead to any cross-node chatting.
    This function only makes a single lookup to a local ETS table.
    All global processes are cached locally to speed up lookup purpose.
  """
  def server_process(name) do
    case :global.whereis_name({__MODULE__, name}) do
      :undefined -> new_process(name)
      pid -> {:ok, pid}
    end
  end

  def action(pid, key) do
    GenServer.call(pid, {:action, key})
  end

  def add_action(pid, key, value) do
    GenServer.cast(pid, {:add_action, key, value})
  end

  def delete_action(pid, key) do
    GenServer.cast(pid, {:delete_action, key})
  end

  def update_action(pid, key, new_value) do
    GenServer.cast(pid, {:update_action, key, new_value})
  end
end
