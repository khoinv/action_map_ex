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
    content =
      case ActionMap.FileStorage.get(file_name) do
        {:ok, contents} -> contents
        {:error, :enoent} -> %{}
      end

    {:noreply, %{state | action_map: content}}
  end

  @impl true
  def handle_call({:action, key}, _from, %{action_map: action_map} = state) do
    {:reply, Map.fetch(action_map, key), state}
  end

  @impl true
  def handle_call({:add_action, key, value}, _from, state) do
    state = %{state | action_map: Map.put(state.action_map, key, value)}
    store(state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:update_action, key, value}, _from, state) do
    state = %{state | action_map: Map.put(state.action_map, key, value)}
    store(state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete_action, key}, _from, state) do
    state = %{state | action_map: Map.delete(state.action_map, key)}
    store(state)
    {:reply, :ok, state}
  end

  # Api

  defp store(%{file_name: file_name, action_map: action_map}) do
    #    ActionMap.FileStorage.store(file_name, action_map)
    ActionMap.FileStorage.store_nodes(
      [Node.self() | ActionMap.Replication.replicas_nodes()],
      file_name,
      action_map
    )
  end

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
    GenServer.call(pid, {:add_action, key, value})
  end

  def delete_action(pid, key) do
    GenServer.call(pid, {:delete_action, key})
  end

  def update_action(pid, key, new_value) do
    GenServer.call(pid, {:update_action, key, new_value})
  end
end
