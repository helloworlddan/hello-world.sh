---
layout: post
title: "Driving CloudFormation Stack Sets with Custom Resources"
date: 2019-03-25
---

![Yo dawg, I heard you like CloudFormation, so I put some CloudFormation on your CloudFormation](/assets/images/driving-stack-sets-with-custom-resources/xzibit.jpg)

This post will discuss the usage of CloudFormation Custom Resources as a
frontend to CloudFormation Stack Sets so you can use a CloudFormation template
to use CloudFormation Stack Sets to deploy lots of CloudFormation stacks. Wait,
**WHAT?!**

# CloudFormation Stack Sets

CloudFormation Stack Sets is a great way to deploy uniform configurations of
resources into multiple regions and accounts in your AWS Organization. Its a
great feature for large scale deployments, really. It is particularly useful in
deploying compliance mechanisms as part of landing zone implementations. A good
example would be a deployment of AWS Config rules to track whether all RDS
database instances and/or snapshots are encrypted across every region and
across every account in your AWS Organization.

Stack Sets allow you to define a uniform CloudFormation template and create a
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

Deployment of the Custom Resource is very straight forward and works exactly as
Chuck describes it in his
[README.md](https://github.com/awslabs/aws-cloudformation-templates/blob/master/aws/solutions/StackSetsResource/README.md).
The Custom Resource gets packaged and deployed with CloudFormation (of course).
Afterward, the Stack Set resource type will be available as `Custom::StackSet`.

To effectively execute Stack Set deployments driven by the resource, we need to
also provision some IAM roles, so that CloudFormation can
actually deploy stacks on you behalf. Two roles are needed:

First off, CloudFormations service principal `cloudformation.amazonaws.com`
needs to be able to `sts:AssumeRole`. This role needs to be present in the
administrative AWS account of the landing zone (I am assuming you know what a
landing zone is) and from now on, we will refer to this role as the
'AdministrationRole'.

Furthermore, we need to provision the 'ExecutionRole'. The ExecutionRole needs
to be available in the accounts in which we actually want to deploy resources
through Stack Sets. This role needs to have a trust relationship with your
administrative AWS account or the AdministrationRole specifically. It also
needs to have enough permissions to execute the CloudFormation template that
you would like to drive through Stack Sets. It might be a good idea to re-use
the administrative role that may or may not be part of your landing zone
environement.

Once all of these roles are in place, a typical Stack Set driven deployment of
a template would assume the roles as follows:

```plain
              sts:AssumeRole                sts:AssumeRole          deployment

CloudFormation            AdministrationRole           ExecutionRole
                +------>                      +------>                 +--->  StackInstance
administrative              administrative    |           target
   account                     account        |          account A
                                              |
                                              |
                                              |
                                              |        ExecutionRole
                                              +------>                 +--->  StackInstance
                                                          target
                                                         account B
```

After putting everything in place, we finally get to actually use the new
abstraction layer we build. The Custom Resource will allow us to use
CloudFormation Stack Sets through the prefered interface: CloudFormation.

# Creating the 'Super Template'

- TODO: Creating super Template

```yaml
Parameters:
  AdministratonRole:
    Type: String
    Description: ARN of the AdministrationRole (local switch-role).
  ExecutionRole:
    Type: String
    Description: Name of the ExecutionRole (Role to assume in target accounts).
  TemplateURL:
    Type: String
    Description: S3 URL of template to deploy to target accounts.
    AllowedPattern: ^https://s3(.+)\.amazonaws.com/.+$
  SetName:
    Type: String
    Description: Name of this Stack Set
  Accounts:
    Type: List<String>
    Description: List of targets accounts
  Regions:
    Type: List<String>
    Description: List of targets accounts

Resources:
  StackSet:
    Type: Custom::StackSet
    Properties:
      ServiceToken:
        Fn::ImportValue: StackSetCustomResource
      StackSetName: !Ref SetName
      TemplateURL: !Ref TemplateURL
      Capabilities:
        - CAPABILITY_IAM
      AdministrationRoleARN: !Ref AdministrationRole
      ExecutionRoleName: !Ref ExecutionRole
      OperationPreferences: {
        "FailureToleranceCount": 500,
        "MaxConcurrentCount": 500
      }
      Tags:
        - Creator: Daniel Stamer
        - Mail: dan@hello-world.sh
      StackInstances:
        - Regions: !Ref Regions
          Accounts: !Ref Accounts
```

# Limits of CloudFormation Stack Sets

- TODO: Soft limits

# Conclusion

- TODO: LZ possibilities
