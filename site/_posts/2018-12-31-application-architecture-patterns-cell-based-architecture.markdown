---
layout: post
title: "Application Architecture Patterns: Limiting the Blast Radius"
date: 2018-12-31
---

# Limiting the Blast Radius

A very common approach in modern cloud-architecture is to design distributed applications in such a way, that they can scale easily. Scaling up will very often hit physical machine limits and it also suffers from the fact that an outage of that single node brings down the entire system. Therefore, scaling out is the preferred method of achieving scalability. Systems that are able to scale out can typically do so virtually limitless (we are just adding more nodes behind some sort of router or load-balancer) and a fault with one of the nodes typically doesn't affect the others.

Now, that seems really nice, but especially that last piece is not always true. There are cases in which a client could cause the fault. In such a scenario, a a client makes some sort of (intentionally or unintentionally) malicious request. The request gets routed through the load-balancer, hits one of the application replicas and causes the fault. The replica goes down, the load-balancer probes notice the unresponsive replica and the subsequent requests get routed to another replica, which will also _go down_. This will continue until all replicas are unavailble. This scenario would dramatically degrade service not just for that one client, but also for all the others. Now, assuming that the application nodes store some sort of state, this could also potentially result in a loss of data.

This post will discuss two different architectural design patterns, which will help to reduce the risk of one malicious client taking out all the application replicas. This is sometimes known as 'limiting the blast radius'. For the sake of simplicity, I am going to assume that the possible applications which would benefit from these designs are already achieving scalability by scaling out rather than scaling up.

# Cell-based Architectures

Cell-based architectures are suitable for stateful applications. The core concept of the cell-based approach is to partition or shard state and other persistent data into cells. Each cell represents are shared-almost-nothing replica of the entire application stack. The router or load-balancer of the application architecture would then route requests to their customer-specific cells. The assignment could be handled based on any kind of algorithm providing that the routing would never change, e.g.: customer A would always be routed to cell 1, customer C would always be routed to cell 2. Hashing algorithms are perfect for this use case, but any other means would do the job too.

There is still a shared component in the architecture: the routing layer. Since this component is shared and absolutely critical, it represents a single point of failure. Therefore, it is advisable to keep this routing layer as thin as possible. Parts of the routing logic could also be implemented into the individual cells. A request that hits cell 1, but belongs to cell 2, could be re-routed to the correct cell 2 by cell 1. The remaining routing layer could then just load-balance (round-robin) requests to the routing component in any cell.

```bash
                                             │
                                             │   request
                                             v
 ┌───────────────────────────────────────────────────────────────────────────────────────┐
 │                    Thinnest Possible Routing Layer / Load-Balancer                    │
 └───────────────────────────────────────────────────────────────────────────────────────┘
    │ stupid           ┌────────────────────────────────────────┐
    │ routing          │        correct re-routing              │
    v                  │                                        v
 ┌───────────────────────────┐ ┌───────────────────────────┐ ┌───────────────────────────┐
 │┌─────────────────────────┐│ │┌─────────────────────────┐│ │┌─────────────────────────┐│
 ││      Routing Layer      ││ ││      Routing Layer      ││ ││      Routing Layer      ││
 │└─────────────────────────┘│ │└─────────────────────────┘│ │└─────────────────────────┘│
 │┌─────────────────────────┐│ │┌─────────────────────────┐│ │┌─────────────────────────┐│
 ││┌──────────┐ ┌──────────┐││ ││┌──────────┐ ┌──────────┐││ ││┌──────────┐ ┌──────────┐││
 │││App Node 1│ │App Node 2│││ │││App Node 1│ │App Node 2│││ │││App Node 1│ │App Node 2│││
 ││└──────────┘ └──────────┘││ ││└──────────┘ └──────────┘││ ││└──────────┘ └──────────┘││
 │└─────────────────────────┘│ │└─────────────────────────┘│ │└─────────────────────────┘│
 │┌─────────────────────────┐│ │┌─────────────────────────┐│ │┌─────────────────────────┐│
 ││┌──────┐ ┌──────────────┐││ ││┌──────┐ ┌──────────────┐││ ││┌──────┐ ┌──────────────┐││
 │││  DB  │ │ Failover DB  │││ │││  DB  │ │ Failover DB  │││ │││  DB  │ │ Failover DB  │││
 ││└──────┘ └──────────────┘││ ││└──────┘ └──────────────┘││ ││└──────┘ └──────────────┘││
 │└─────────────────────────┘│ │└─────────────────────────┘│ │└─────────────────────────┘│
 │           Cell 1          │ │          Cell 2           │ │          Cell n           │
 └───────────────────────────┘ └───────────────────────────┘ └───────────────────────────┘

```

This design pattern cannot only be applied to frontend clients hitting application servers, but also to application servers hitting the database layers. Typically, one would use managed PaaS-like services to take care of the heavy-lifting of operating database servers. A good example would be to use AWS RDS to provide a relational data store. This approach should generally be preferred, but it is not always feasible. AWS RDS can only scale up to a certain point and as soon as an application is facing write contention or the size of the database is simply too big for RDS this approach becomes unusable. At this point, you could consider operating your own unmanaged cell-based relational database layer. Write operations to the database (and the customer data they are about to mutate) can be sharded across multiple independent servers. At this point, you could also think about using multiple RDS instances, one for each shard.

A challenge in operating stateful cell-based architectures is cell migration. Cell migration refers to the relocation of all state and other data from one cell to another. This is typically done by having some sort of mechanism that is capable of creating a complete shadow copy of the cell. This new cell clone is a fully-functional cell with all of its components. The mechanism should then continue to copy modifications from the old cell to the new and as soon as they have achieved synchronicity, the cells are frozen and the cut-over to the new cell is executed, similar to how one would execute data center migrations. A lot of things can go wrong during cell migrations and it is extremely challenging to get it right.

# Shuffle Sharding

Shuffle Sharding uses techniques similar to cell-based architectures but it is only suitable for stateless applications or applications that pertain a so-called soft-state. Shuffle Sharding becomes feasible in applications that already load-balance traffic across four, five or more application server replicas.

In the Shuffle Sharding design pattern, you would switch out the (simple) load-balancer of your application architecture and replace it with a routing layer that is aware of Shuffle Sharding. The implementation is fairly simple. Each customer gets assigned two or more application replicas and _this assignment is permanent_. The following illustration shows assignment to application replicas by Shuffle Sharding.

```bash

 ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
 │ Customer A │ │ Customer B │ │ Customer C │ │ Customer D │
 └────────────┘ └────────────┘ └────────────┘ └────────────┘
 ┌─────────────────────────────────────────────────────────┐
 │             Shuffle Sharding Routing Layer              │
 └─────────────────────────────────────────────────────────┘
 ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
 │ App Node 1 │ │ App Node 2 │ │ App Node 3 │ │ App Node 4 │
 └────────────┘ └────────────┘ └────────────┘ └────────────┘

   Customer B     Customer A     Customer B     Customer A
   Customer C     Customer C     Customer D     Customer D

```

The illustration shows four different customers sharded across four application replicas. Underneath the app nodes, you'll find the permanent assignment of customers to the corresponding node.

Now, what's the point of all of this? Simple: it is all about failure containment or limiting the blast radius. Let's reiterate the scenario from the introduction. Imagine customer A would introduce a malicious request, that would not only cause app node 2 but also app node 4 to go down. Customer A got load-balanced across all of the two assigned nodes until both are taken out. Now, customer C and customer D have also been using the failing nodes 2 and 4, but due to the shuffled assignment they still have access to node 1 (customer C) and node 4 (customer D)! The quality of service might be degraded, but the service is still responding.

The name of Shuffle Sharding has been given to it because of it's similarities to shuffling a deck of cards and how likely it is, that players would be dealt the same cards. Think of the application nodes as the cards and the customers as the players. In the example above, we are dealing two cards of four kinds to four players. The more cards of greater variety are being dealt out, the less likely the chance of dealing out the same hand to different players. If no hands are the same, players will always have at least one different card. Hence, they had at least one application node that is unaffected by the other players.

# Conclusion

Both design patterns can help you in those scenarios in which you want to limit the blast radius caused by a malicious request so that as few as possible other clients are affected by the damage. Both patterns achieve this by using horizontal shards and clever routing mechanisms for damage containment.