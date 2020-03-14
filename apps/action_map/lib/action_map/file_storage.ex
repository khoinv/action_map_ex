defmodule ActionMap.FileStorage do
  @moduledoc false
  @store_folder './action_map_store_folder'

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

  defp get_file_name(key) do
    Path.join(@store_folder, to_string(key))
  end

  ## Api
  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end
end
