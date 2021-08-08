## ActionMap
Learning the distributed system by implementing action_map server

### TODO LIST
+ [ ] Data compression
+ [ ] Store only frequently used data in memory, and the rest on disk
+ [x] Data partition
+ [x] Data replication
+ [ ] Improve data partition by using consistent hashing
+ [ ] Reducing the amount of data be passed across nodes when replication
+ [ ] Consistency
+ [ ] Inconsistency resolution
+ [ ] Handling failures
+ [ ] System architecture diagram
+ [ ] Write path
+ [ ] Read path
+ [ ] Benchmarking


## Requirement
- elixir 1.9

## Run
### `mix test`
#### NOTE: To running test with multiple nodes, you must have ensured that epmd has been started before tests will be run.
Typically with `epmd -daemon`.
