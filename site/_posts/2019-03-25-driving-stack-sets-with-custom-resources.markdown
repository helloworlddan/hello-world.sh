---
layout: post
title: "Driving CloudFormation Stack Sets with Custom Resources"
date: 2019-03-25
---

![Yo dawg, I heard you like CloudFormation, so I put some CloudFormation on your CloudFormation](/assets/images/driving-stack-sets-with-custom-resources/xzibit.jpg)

This post will discuss the usage of CloudFormation custom resources as a
frontend to CloudFormation stack sets so you can use a CloudFormation template
to use CloudFormation stack sets to deploy lots of CloudFormation stacks. Wait,
WHAT?

# CloudFormation Stack Sets

CloudFormation stack sets is a great way to deploy uniform configurations of
resources into multiple regions and accounts in your AWS Organization. Its a
great feature for large scale deployments, really. It is particularly useful in
deploying compliance mechanisms as part of landing zone implementations. A good
example would be a deployment of AWS Config rules to track whether all RDS
database instances and/or snapshots are encrypted across every region and
across every account in your AWS Organization.

Stack sets allow you to define a uniform CloudFormation template and create a
so-called stack set definition around it. This definition holds configuration
parameters as to how to deploy the associated CloudFormation template. It
includes role definitions for CloudFormation to actually deploy things as well
as other various parameters to define how the deployment happens. Once the
definition is created, it is possible to create so-called stack instances in
the set. An instance is basically a representation of a CloudFormation stack
deployed in a single account into a single region. Afterwards, CloudFormation
stack sets will then attempt to actually deploy the stack as part of an
operation.

- TODO: the problen with the api, no cfn support
- TODO: enter awslabs-project

# Deploying the Custom Resource

- TODO: lambda deployment (using CloudFormation, duh)

# Creating the 'Super Template'

- TODO: sceptre mega template

# Limits of CloudFormation Stack Sets

- TODO: Soft limits

# Conclusion

- TODO: LZ possibilities
