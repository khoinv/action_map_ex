defmodule ActionMap.Utils do
  def list_nodes(key) do
    {:ok, nodes} = ActionMap.HashRing.find_nodes(key)
    nodes
  end

  def list_replicas_nodes(key) do
    self = Node.self()
    {_, replicas_nodes} = Enum.split_while(list_nodes(key), &(&1 != self))

    replicas_nodes
  end

  def attempt_rpc_call(_, _, 0, _), do: true

  def attempt_rpc_call(nodes, [module, function_name, args], expect_success_nodes_count, timeout) do
    {execute_nodes, backup_nodes} =
      Enum.split_while(Enum.with_index(nodes), fn {_node, idx} ->
        idx < expect_success_nodes_count
      end)

    {results, bad_nodes} =
      :rpc.multicall(
        execute_nodes
        |> Enum.map(fn {node, _idx} -> node end),
        module,
        function_name,
        args,
        timeout
      )

    if Enum.count(bad_nodes) == 0 do
      [first_result | _tails] = results
      first_result
    else
      attempt_rpc_call(
        backup_nodes,
        [module, function_name, args],
        Enum.count(bad_nodes),
        timeout
      )
    end
  end
end
