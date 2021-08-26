defmodule ActionMap.HashRing do
  @doc """
    TODO: Dig into murmur3 hashing function. That is a non secure and more evenly distributed hashing.
    TODO: Dig into Partitioning and placement of keys strategies, ex: Q/S tokens per node, equal-sized partitions
  """
  use GenServer
  alias ExHashRing.Ring
  defstruct ring: nil

  @replicas_count Application.get_env(:action_map, :replicas_count)
  @vnodes_count Application.get_env(:hash_ring, :vnodes_count)

  def start_link(_) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    send(self(), :load_existed_nodes)
    {:ok, ring} = Ring.start_link()

    {:ok, %{state | ring: ring}}
  end

  @impl true
  def handle_info(:load_existed_nodes, state) do
    for node <- Node.list([:this, :visible]) do
      {:ok, _} = Ring.add_node(state.ring, node, @vnodes_count)
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:add_node, node, w}, _from, state) do
    {:reply, Ring.add_node(state.ring, node, w), state}
  end

  @impl true
  def handle_call({:find_nodes, key, num}, _from, state) do
    {:reply, Ring.find_nodes(state.ring, key, num), state}
  end

  @impl true
  def handle_call({:find_node, key}, _from, state) do
    {:reply, Ring.find_node(state.ring, key), state}
  end

  def add_node(node, vnodes_count \\ @vnodes_count) do
    GenServer.call(__MODULE__, {:add_node, node, vnodes_count})
  end

  def find_node(key) do
    GenServer.call(__MODULE__, {:find_node, key})
  end

  def find_nodes(key, replicas_count \\ @replicas_count) do
    GenServer.call(__MODULE__, {:find_nodes, key, replicas_count})
  end
end
