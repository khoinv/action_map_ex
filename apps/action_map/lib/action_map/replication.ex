defmodule ActionMap.Replication do
  @replicas Application.get_env(:action_map, :replicas)

  def replicas_nodes(nodes, node) do
    current_node_idx = Enum.find_index(nodes, &(&1 == node))
    node_count = Enum.count(nodes)

    for i <- 1..@replicas do
      Enum.at(nodes, rem(current_node_idx + i, node_count))
    end
  end

  def replicas_nodes do
    replicas_nodes(Node.list([:this, :visible]), Node.self())
  end
end
