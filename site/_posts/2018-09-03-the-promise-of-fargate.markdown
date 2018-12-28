---
layout: post
date: 2018-09-03
title: "The Promise of Fargate"
---

# Just run this container for me

With everybody's attention being almost completely on the recent AWS EKS
(Elastic Container Services for Kubernetes) developments, I felt that another
(subjectively) more important ECS announcement is easily overlooked by many:
AWS Fargate. Yupp, this post is about Fargate and why it is such an important
service (especially if you write CloudFormation or operate workloads).

The future of running containers in the cloud is about the next layer of
abstraction, about moving from machine-level abstraction to process-level
abstraction. We don't really care how the container is executed. Here is
container icon [@kelseyhightower](https://twitter.com/kelseyhightower) putting
it in very simple, but complete words:

{% twitter https://twitter.com/kelseyhightower/status/1002613402747920384 %}

(Note that, K8S pods are roughly the same concept as ECS tasks)

And that is exactly what it is: AWS Fargate lets you run containers on AWS
using the ECS container orchestrator without having to worry about the
underlying infrastructure. If you ever bootstrapped a properly functioning,
auto-scaling ECS cluster in CloudFormation you know how cumbersome it can be.

From an operations perspective, Fargate is basically a serverless technology
because the service hides (abstracts) the node/machine from the consumer. This
becomes even more apparent with the latest time and event-based scheduling
features announced by Deepak Dayama, Product Lead of Fargate and ECS:

{% twitter https://twitter.com/saysdd/status/1034610825741316096 %}

The integration of event-based triggers for Fargate lets developers integrate
long-running tasks into serverless architectures, which would otherwise be
limited by the execution timeouts of Lambda. 

It is worth mentioning that other public cloud providers also started to offer
very similar service offerings. Microsoft Azure's ACI (Azure Container
Instances) is a good example.

It is important to understand, that the true innovation lies in the shift of
responsibility. It shifts one step upwards from machine-level isolation (EC2)
to process-level isolation (Fargate).

AWS has enough trust in container isolation to also assume responsibility of
the underlying infrastructure so that consumers don't need to worry about it
anymore. It enables developers to focus on what is important.

This is the promise of Fargate.

# AWS Fargate

So essentially, Fargate is a new launch type for ECS. Previously, it was only
able to use the launch type EC2, which is nothing but running a bunch of EC2
instances (probably with ECS-optimized AMIs in an Auto-Scaling group) and
connecting the ECS agent to your ECS service definitions.

The Fargate launch type enables developers to omit the EC2 definitions. An ECS
task will be scheduled to launch on warm, AWS-maintained container hosts. Each
Fargate launch has to be configured with a fixed task size. This task size
basically controls the _cgroups_ limits set by the Fargate service on the
executing host node. The task size is also what determines how much you will
pay for the Fargate service. You will only pay for what you set the maximum
resource consumption for your task to. This new way of running containers on
the AWS cloud comes with a few limitations and new concepts and I am going to
try to point out the most important ones.

## Networking

The most important new concept is the _awsvpc_ networking mode. With _awsvpc_
networking, each Fargate task will have its own isolated networking stack.
Fargate will provision a new Elastic Network Interface (ENI) for each task.
This ENI sits in a subnet in one of your VPCs, gets a regular private IP
address and can also have a public IP address. Since each exposed container
port of the task is directly addressed through the ENI, there is no need for
dynamic ports (no port conflicts).

Considerations for where to place the ENIs of your tasks are basicallly the
same as with classic EC2. Tasks that listen for incoming traffic should be
fronted with a load balancer. Target groups for Elastic Load Balancers should
track 'ip' targets, since that is how you'd also normally route traffic to
ENIs. If you expect your Fargate task to have a lot of outgoing traffic, you
can place the ENI into a public subnet so traffic is not affected by a
possible burst limit on your NAT Gateways.

## Limitations

Since Fargate does not run on you own instances, it is important to mention
that the service offering comes with certain limitations for your tasks.

It is (obviously) not possible to run your task in _privileged_ mode. This is a
hard requirement to guarantee proper process isolation and to ensure that a
rogue task cannot damage the underlying container host. Keeping up this
isolation is integral to the promise of Fargate. If you need privileged
containers, you will need to use the EC2 launch type. I am not suggesting that
this is a good idea though. Maybe one should look into launching regular EC2
instances, run the process without containerization and keep the instances as
ephemeral as possible.

Fargate also sets up hard limits. You container images cannot be bigger than 4
GB and each container has a local filesystem usage quota of 10 GB. If you want
to shared volumes between containers, these volumes have a maximmum size of 4
GB.

Fargate also only supports using the _awslogs_ driver, so you can only ship
STDOUT streams to CloudWatch logs. Of course you can then move your logs out of
CloudWatch logs to some other place and do whatever you want with them.

There are a bunch of other limits, which are worth checking out before
migrating workloads to Fargate. Be sure to RTFM.

## Pricing

When it comes to comparing pricing differences between the launch types, one
could naively try and compare the performance-to-price ratio of EC2 and
Fargate. The cost for infrastructure are not completely gone, just because the
underlying instances have been hidden from the service consumer. _Somebody_
still has to pay for it. That is why one vCPU hour on Fargate is going to be
more expensive than the same amount of compute on EC2: The underlying
infrastructure is still needed! When you are running tasks on EC2, it is
important to understand that not all of the instances resources can be utilized
to run the actual application workload. You are paying for the entire instance.
In Fargate, 100% of the compute that you pay for is directly used by your
actual application. This basically eliminates waste.

What you should really compare, is the amount of development time you need to
invest to properly setup an auto-scaling EC2-based ECS cluster in
CloudFormation. It can take quite some debugging time to set up all components,
like the CloudWatch agent to forward logs and OS-level metrics. Additionally,
operations isn't free as well. You still need to have some ops people in place
to maintain the container host, no matter how much of the architecture is
automated. Occasionally, you would also need to perform upgrades of instance
generations or AMI base images. All of these tasks vanish when running your
workloads on Fargate.

You can find detailed Fargate pricing information
[here](https://aws.amazon.com/fargate/pricing/).

# Quicklaunch with Fargate

I have created a [Fargate Quicklaunch
Repo](https://github.com/daniceman/fargate-quicklaunch). It uses
[@cloudreach](https://twitter.com/cloudreach)
[sceptre](https://github.com/cloudreach/sceptre) as deployment driver for AWS
CloudFormation. The repository acts as blueprint for one of the most common
deployment scenarios. It provisions an ECS cluster, which is fronted with an
TLS-offloading Application Load Balancer (ALB) and deploys a web-serving
container on the Fargate launch type.

The most important Fargate-specific resource definitions are shown in the
following extract from the deployment.

```yaml
Resources:
  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      ExecutionRoleArn: !Join [ ":", [ "arn", "aws", "iam", "", !Ref "AWS::AccountId", "role/ecsTaskExecutionRole"]]
      TaskRoleArn: !Join [ ":", [ "arn", "aws", "iam", "", !Ref "AWS::AccountId", "role/ecsTaskExecutionRole"]]
      Cpu: !Ref Cpu
      Memory: !Ref Memory
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      ContainerDefinitions:
        - Name: !Ref Name
          Image: !Ref Image
          PortMappings:
            - ContainerPort: !Ref Port

  Service:
    Type: AWS::ECS::Service
    Properties:
      Cluster: !Ref Cluster
      ServiceName: !Ref Name
      LaunchType: FARGATE
      DesiredCount: !Ref DesiredCount
      DeploymentConfiguration:
        MaximumPercent: !Ref DeploymentMaximumPercent
        MinimumHealthyPercent: !Ref DeploymentMinimumHealthyPercent
      TaskDefinition: !Ref TaskDefinition
      LoadBalancers:
        - ContainerName: !Ref Name
          ContainerPort: !Ref Port
          TargetGroupArn: !Ref TargetGroup
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: DISABLED
          Subnets: !Split [ ",", !Ref PrivateSubnetIds ]
          SecurityGroups:
            - !Ref ClusterSecurityGroup

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Join [ "-" , [ !Ref Cluster, !Ref Name, "tg" ] ]
      HealthCheckIntervalSeconds: "20"
      HealthCheckPath: "/"
      HealthCheckPort: !Ref Port
      HealthCheckProtocol: HTTP
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 2
      TargetType: ip
      Port: !Ref Port
      Protocol: HTTP
      VpcId: !Ref VpcId
      Tags:
      - Key: Name
        Value: !Join [ "-" , [ !Ref Cluster, !Ref Name, "tg" ] ]
```

Note how this is relying on the presence of certain resources. The
service-linked role for ECS needs to be present in your account. CloudFormation
will not create it for you automatically. It can be explicitly created like
this:

```bash
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com
```

The CloudFormation templates are also referencing an IAM role, which is being
assumed by the running tasks to grant them the most basic permissions (pulling
container images, writing log events). These permissions are provided by the
AWS-managed policy _AmazonECSTaskExecutionRolePolicy_ and the role can be
created like this:

```bash
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --role-name ecsTaskExecutionRole
```

# Conclusion

The most amazing experience about migrating workloads from the EC2 launch type
to Fargate was that I was able to delete _so much_ Code. Thinking about how
much engineering time it needed to originally write this code makes me _love_
Fargate. I am eager to experiment further with the recent announcements around
time and event-based triggers for executing Fargate tasks, since this would
finally present a feasible method of integrating long-running tasks into
serverless architectures on AWS.

All in all, Fargate allows engineers to focus on running their workloads without
the need to maintain the necessary infrastructure:

Just run this container for me, I don't care how and please don't tell me.