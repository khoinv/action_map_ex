defmodule ActionMap.FileStorage do
  @moduledoc false
  @store_folder './priv/store_folder'
  @timeout 60_000

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_) do
    send(self(), :real_init)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:real_init, state) do
    File.mkdir_p!(@store_folder)
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    data =
      case File.read(get_file_name(key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> %{}
      end

    {:reply, data, state}
  end

  @impl true
  def handle_cast({:store, key, data}, state) do
    key
    |> get_file_name()
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete, key}, state) do
    key
    |> get_file_name()
    |> File.rm!()

    {:noreply, state}
  end

  defp get_file_name(key) do
    Path.join(@store_folder, to_string(key))
  end

  ## Api
  def get(key) do
    with_pool(fn worker -> GenServer.call(worker, {:get, key}) end)
  end

  def store(key, data) do
    with_pool(fn worker -> GenServer.cast(worker, {:store, key, data}) end)
  end

  def store_all_nodes(key, data) do
    {_results, bad_nodes} =
      :rpc.multicall(
        __MODULE__,
        :store,
        [key, data],
        @timeout
      )

    0 = Enum.count(bad_nodes)
  end

  def delete(key) do
    with_pool(fn worker -> GenServer.cast(worker, {:delete, key}) end)
  end

  defp with_pool(callback) do
    Task.async(fn ->
      :poolboy.transaction(
        ActionMap.FileStorage.Pool,
        fn worker -> apply(callback, [worker]) end,
        @timeout
      )
    end)
    |> Task.await(@timeout)
  end
end
