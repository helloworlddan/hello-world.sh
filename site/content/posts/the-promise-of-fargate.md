+++ 
draft = true
date = 2018-08-16T15:54:44+02:00
title = "The Promise of Fargate"
slug = "" 
tags = []
categories = []
+++

### Just run this container for me, please

With everybody's attention being almost completely on K8s/EKS this is where we should really look in terms of ops/responsibility: the promise of fargate.

Just run this Pod/Task for me

{{< tweet 1002613402747920384 >}}

Shift in responsiblility: one layer up.

Basically serverless ... especially with the latest time and event-based scheduling features announced by Deepak Dayama, Product Lead of Fargate and ECS:

{{< tweet 1034610825741316096 >}}

The integration of event-based triggers for Fargate lets developers integrate long-running tasks into serverless architectures, which would otherwise be limited by the execution timeouts of Lambda. 

Other public cloud providers:  Azure ACI, whereas AWS only with full cost additional services Beanstalk, opsworks...

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
