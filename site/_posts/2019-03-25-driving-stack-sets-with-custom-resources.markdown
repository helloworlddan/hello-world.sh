---
layout: post
title: "Driving CloudFormation Stack Sets with Custom Resources"
date: 2019-03-25
---

![Yo dawg, I heard you like CloudFormation, so I put some CloudFormation on your CloudFormation](/assets/images/driving-stack-sets-with-custom-resources/xzibit.jpg)

This post will discuss the usage of CloudFormation Custom Resources as a
frontend to CloudFormation Stack Sets so you can use a CloudFormation template
to use CloudFormation Stack Sets to deploy lots of CloudFormation stacks. Wait,
WHAT?

# CloudFormation Stack Sets

CloudFormation Stack Sets is a great way to deploy uniform configurations of
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
deployed into a single account into a single region. Afterward, CloudFormation
Stack Sets will then attempt to actually deploy the stack as part of an
operation.

However, CloudFormation Stack Sets do not come with actual CloudFormation
support themselves. Other CloudFormation resource types like Macros or Custom
Resources actually are supported and you are able to create their definitions
in native CloudFormation templates. Stack Sets, however, lack this support.

Luckily, the world has [Chuck Meyer](https://twitter.com/chuckm) in it and
Chuck wrote a CloudFormation Custom Resource to drive CloudFormation Stack Set
deployments. The code for the Custom Resource is available [on
Github](https://github.com/awslabs/aws-cloudformation-templates/tree/master/aws/solutions/StackSetsResource).

# Deploying the Custom Resource

- TODO: lambda deployment (using CloudFormation, duh)

# Building a Target Template


# Creating the 'Super Template'

- TODO: sceptre mega template

# Limits of CloudFormation Stack Sets

- TODO: Soft limits

# Conclusion

- TODO: LZ possibilities
