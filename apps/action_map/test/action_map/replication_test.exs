defmodule ActionMap.ReplicationTest do
  use ExUnit.Case
  alias ActionMap.Replication

  @moduletag :capture_log

  test "replication nodes index" do
    nodes = LocalCluster.start_nodes("test-cluster", 5, files: [__ENV__.file])
    [node1, node2, node3, _node4, node5] = nodes
    assert [^node2, ^node3] = Replication.replicas_nodes(nodes, node1)
    [^node1, ^node2] = Replication.replicas_nodes(nodes, node5)
  end
end
