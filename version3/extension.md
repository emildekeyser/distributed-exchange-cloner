# Permanent Evaluation 3 extension: Managing your rate

## Rules

Your code will need to be submitted through GitHub Classroom.

The deadline for committing your code is `Monday 10 August 8:00AM`. Starting from Monday 10 August 8:01AM, a script will clone your repository with your solution.

__File creation/last edit time is of no relevance at all for this deadline! Your code should be online at this moment in time.__

If for some mysterious reason GitHub should be offline, you are allowed to send it by mail. GitHub uptime will also be monitored.

_This might be obvious, but not having internet access is by no means a reason to not submit your code before the deadline._

There can be small changes to this assignment (function names, small adjustments, etc...).

## Assignment

This extension is only for the students which didn't pass the first time. The general idea is to create an extra project (similar to our reporter) that'll limit our rate over different nodes.

## Requirements

* Your node should automatically join the cluster
* Other nodes do not depend on this node. This means that they are not aware that this node exists, but they will see the node name in the cluster. They do not require this node to be active/running in order to function normally.
* At the start, this node will do nothing. It'll start up and wait for user input.
* You can add a group of cloning nodes whose rate needs to be managed. An example would be `RateManager.add_group :local_group`. A newly created group its __default rate limit is 5__.
* After which you can add nodes to that group. E.g. `RateManager.add_node_to_group :local_group, :cloner_node_1`. This can return following responses:
  * `:ok`
  * `{:error, :group_not_present}`
  * `{:error, :node_does_not_exist}`
* Every 10 seconds it will check and adjust the rates of the cloning nodes. The rate across the nodes should be equal if possible.
* When a node disconnects, it will be detected by the periodic check. When this happens, it should be removed from your group and the remaining nodes will be able to clone more.
* You can request an overview of the groups with `RateManager.list_groups`, which will return a map of groups. E.g. `%{local_group: %{nodes: [:cloner_node_1, :cloner_node_2], rate: 5}}`

### Hint

Use the Erlang `:rpc` module to set the rate on your other nodes.

## Sample flow of application

* Node 1 is started
* Node 1 detects no other nodes and starts cloning
* Node 2 is started
* Node 2 detects other nodes and it doesn't start cloning automatically
* Node 3 is started
* Node 3 detects other nodes and it doesn't start cloning automatically
* RateManager node is started
* A new group is created in the RateManager
* You set the group rate limit to 4
* You add Node 1 to this group
* You add Node 2 to this group
* You add Node 3 to this group
* You balance on a random node, the effect should be the same. They should all start/be cloning.
* At this point in time, the rate limit accross the nodes should be either:
  * 1-1-1 req/s
  * 1-1-2 req/s
  * 1-2-1 req/s
  * 2-1-1 req/s
* You shut Node 3 down and balance again on one of the remaining nodes
* Node 1 and Node 2 their rate limit should be 2
* Node 3 should no longer be in your RateManager its group list
