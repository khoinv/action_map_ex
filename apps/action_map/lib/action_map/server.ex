defmodule ActionMap.Server do
  @moduledoc false
  alias ActionMap.ActionMapRegistry
  @timeout 1000
  @replicas_count Application.get_env(:action_map, :replicas_count)

  use GenServer

  defstruct file_name: nil, action_map: %{}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: ActionMapRegistry.via_tuple(opts[:name]))
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
  def new_process(name) do
    case DynamicSupervisor.start_child(
           ActionMap.Supervisor,
           {__MODULE__, [file_name: name, name: name]}
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp store(%__MODULE__{file_name: file_name, action_map: action_map}) do
    ActionMap.FileStorage.store(file_name, action_map)

    ActionMap.Utils.attempt_rpc_call(
      ActionMap.Utils.list_replicas_nodes(file_name),
      [ActionMap.FileStorage, :store, [file_name, action_map]],
      @replicas_count - 1,
      @timeout
    )
  end
end
