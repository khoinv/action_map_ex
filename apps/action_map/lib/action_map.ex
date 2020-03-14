defmodule ActionMap do
  @moduledoc false

  use GenServer
  @timeout 60_000

  defstruct map_key: nil, action_map: %{}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:global, opts[:name]})
  end

  @impl true
  def init(opts) do
    send(self(), :real_init)
    {:ok, %{map_key: opts[:map_key], action_map: %{}}}
  end

  @impl true
  def handle_info(:real_init, %{map_key: map_key} = state) do
    action_map =
      Task.async(fn ->
        :poolboy.transaction(
          ActionMap.FileStorage.Pool,
          fn worker -> ActionMap.FileStorage.get(worker, map_key) end,
          @timeout
        )
      end)
      |> Task.await(@timeout)

    {:noreply, %{state | action_map: action_map}}
  end

  def handle_info(:store, %{map_key: map_key, action_map: action_map} = state) do
    Task.async(fn ->
      :poolboy.transaction(
        ActionMap.FileStorage.Pool,
        fn worker -> ActionMap.FileStorage.store(worker, map_key, action_map) end,
        @timeout
      )
    end)
    |> Task.await(@timeout)

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
  def start(name, map_key) do
    DynamicSupervisor.start_child(
      ActionMap.Supervisor,
      {__MODULE__, [map_key: map_key, name: name]}
    )
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
