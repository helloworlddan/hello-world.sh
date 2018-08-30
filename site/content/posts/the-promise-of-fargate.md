+++ 
draft = true
date = 2018-08-16T15:54:44+02:00
title = "The Promise of Fargate"
slug = "" 
tags = []
categories = []
+++

### Just run this container for me, please

With everybody's attention being almost completely on the recent AWS EKS
(Elastic Container Services for Kubernetes) developments, I felt that another
(subjectively) more important ECS announcement is easily overlooked by many:
AWS Fargate. Yupp, this post is about Fargate and why it is such an important
service (especially if you write CloudFormation or operated workloads).

The future of running containers in the cloud is about the next layer of
abstraction, about moving from machine-level abstraction to process-level
abstraction. We don't really care how the container is executed. Here is
container icon [@kelseyhightower](https://twitter.com/kelseyhightower) putting
it in very simple, but complete words:

{{< tweet 1002613402747920384 >}}

(Note that, K8S pods are roughly the same concept as ECS tasks)

And that is exactly what it is: AWS Fargate lets you run containers on AWS
using the ECS container orchestrator without having to worry about the
underlying infrastructure. If you ever bootstrapped a properly functioning,
auto-scaling ECS cluster in CloudFormation you know how cumbersome it can be.

From an operations perspective, Fargate is basically a serverless technology
because the service hides (abstracts) the node/machine from the consumer. This
becomes even more apparanet with the latest time and event-based scheduling
features announced by Deepak Dayama, Product Lead of Fargate and ECS:

{{< tweet 1034610825741316096 >}}

The integration of event-based triggers for Fargate lets developers integrate
long-running tasks into serverless architectures, which would otherwise be
limited by the execution timeouts of Lambda. 

It is worth mentioning that other public cloud providers also start to offer
very similar service offerings. Microsoft Azure's ACI (Azure Container
Instances) is a good example.

It is important to understand, that the true innovation lies in the shift of
responsibility. It shifts one step upwards from machine-level isolation (EC2)
to process-level isolation (Fargate).

AWS has enough trust in container isolation to also assume responsibility of
the underlying infrastructure, so that consumers don't need to worry about it
anymore. It enables developers to focus on what is important. This is the
promise of Fargate.

### AWS Fargate

AWS Fargate is a new launch type for ECS.

#### Networking

AWSVPC networking mode.

#### Limitations

No privileged mode. Filesystem limits. 

#### Pricing

Actually compare pricing to something feasible.

Compare developer cost vs. time-saving of Fargate.

### Quickstart with Fargate

Code gist here

role/ecsTaskExecutionRole && service-linked role may need to be created by hand (Web UI)

### Conclusion

Migrating old projects, deleting code.
