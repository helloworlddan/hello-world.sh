+++ 
draft = false
date = 2018-08-09T20:00:00+02:00
title = "Deploying reusable, higher-level resources with AWS-CDK"
slug = "" 
tags = []
categories = ["AWS", "IAC", "CDK", "TypeScript", "SNS", "Lambda", "CloudFormation"]
+++

### Introducing the AWS-SDK

AWS recently released the [Cloud Development
Kit (CDK)](https://github.com/awslabs/aws-cdk). According to the authors of the
CDK, it is _an infrastructure modeling framework that allows you to define your
cloud resources using an imperative programming interface_.

The AWS CDK is basically a wrapper around CloudFormation, which abstracts
CloudFormation definitions of AWS resources into an object-oriented library.
This allows developers to define higher-level abstractions of resources, which
can easily be reused. It also allows for deeper integration into application
code and more dynamic generation of resources. The AWS CDK can then be used to
render the higher-level definitions into CloudFormation templates. A developer
can also choose to generate a diff of resources to create or update and
directly deploy resource definitions to the cloud. The CDK will even take care
of generating additional CloudFormation resource to supply the necessary
deployment infrastructure (e.g., a S3 bucket to hold zipped Lambda functions).

"But wait!", could you say now, "Isn't that what Troposhere is for?!". Well,
yes and no. To some extend
[Troposphere](https://github.com/cloudtools/troposphere) (and I'm sure there
other libraries for other languages) enables developers to define
CloudFormation templates with can be dynamically accessed from within other
Python workloads. However, Troposphere only does half of what the AWS CDK does.
Troposphere aims more at providing a more dynamic way of rendering
CloudFormation templates. It does not provide deployment tooling and it does
not provide abstraction of resources as high as the CDK.

Currently, the AWS CDK ships support for Java and TypeScript. The latter will
be transpiled into JavaScript before being rendered into CloudFormation.

### A real-world use-case

I am going to quickly lay out a real-world use-case to demonstrate usage of the
AWS CDK.

A recent project was governing a large corporate AWS estate. The top two
focuses of the project was governance of AWS accounts for multiple development
teams and managing additional development tools on top of the AWS estate.
Requirements for heavy automation led us to build an Account Vending Machine
(AVM) that would automatically configure AWS accounts for development teams. To
further automate our AVM, it would also need to be able to configure the
development tools. For example: If a new development team is formed, the AVM
would automatically create AWS accounts for the team. Furthermore, the AVM
needs to trigger off some other automation tool to configure applications like
[Slack](https://slack.com) to setup some defaults inside of it (e.g.: default
channels).

Our application was holding the layout of the organization in some database and
every time something in the organization configuration would change (e.g.: a new
development team gets added), the automation has to run off and do it's job. 

The following shows an architecture that relies on SNS and Lambda (or
StepFunctions) to do run a multitude of configuration tasks. Configurations
are divided up into two categories: Organization configuration is holding
configuration that is application-agnostic, like the layout of all development
teams. The second configuration category would be application specific. This
could be something like setting up federation for a specific application. 

![Use-case architecture layout](/images/deploying-reusable-higher-level-resources/arch.png)

As you can see, updates to configuration are being push to SNS topics.
Application-agnostic updates are fanned out to all service configurators,
whereas application-specific updates are only pushed to a specific
configurator.

It shouldn't be hard to detect the obvious pattern in the architecture diagram.

### Let's get started

This post assumes that you have `npm` installed.

Let's install the AWS CDK!
```
$ npm i -g aws-cdk
```

We are going to setup a project directory and initialize it with the CDK. I am
choosing TypeScript to built this project.
```bash
$ mkdir cdk-setup-service
$ cd cdk-setup-service
# Initialize the project. NOTE: you could also use --language java
$ cdk init app --language typescript
```

That's it! The CDK will auto-generate some code that would setup an SNS topic
and an SQS queue.

### Building our solution

I am creating a class to that aims at encapsulating the pattern that is
obviously repeating in the architecture. We need one Lambda function per
application to compute changes and update to our organizational layout and one
Lambda function to process all the application-specific updates. Additionally,
we need to setup a bunch of SNS topics and subscription to do all the
event-based plumbing to make the whole thing work.

The following TypeScript classes defines acts like an umbrella, holding all the
required resources to setup Service Configurators for one application. I am
going to save it to `bin/cdk-service-configurator.ts`

{{< gist daniceman e77c9e87e49e0db7a9603d8e9e67cfa2  >}}

Nice. The Service Configurator can now be instantiated for every application
that requires configuration. Note how the Service Configurator expects to find
the Python code for it's Lambda functions in a very specific directory.

The current layout of the project directory looks like this (node_modules
redacted for obvious reasons):

```
$ tree
.
├── README.md
├── bin
│   ├── cdk-service-configurator.ts
│   ├── cdk-setup-service.ts
│   └── lambda
│       └── slack
│           ├── application-update-handler
│           │   └── index.py
│           └── organization-update-handler
│               └── index.py
├── node_modules
├── cdk.json
├── package-lock.json
├── package.json
└── tsconfig.json
```

Let's change the auto-generated file `bin/cdk-setup-service.ts` so it
references our Service Configurator. We are also going to instantiate it for
the application Slack.

{{< gist daniceman 73e4c5eaa34f94033827b6fe4ebec82b  >}}

Okay! That should be it! `bin/cdk-setup-service.ts` defines a class, which
inherits from cdk.Stack and instantiates a global topic for
application-agnostic updates and an instance of the Service Configurator for
Slack.

### Deploying to the cloud

Okay, let's get cracking and deploy our project to the cloud. After we make
sure that our current environment has valid AWS credentials loaded, we can get
to work.

Firstly, we need to transpile our TypeScript code to JavaScript.
```
$ npm run build 
```

Okay, now since our deployment requires the usage of assets (zipped Lambda
function code), we need to instruct the CDK to bootstrap our environment.
This will create a bucket to save our Lambda code packages in.
```
$ cdk bootstrap
```

Now we can use the CDK to compute a diff between the resources that are already
deployed and the changes that the CDK would hand to CloudFormation to deploy
now. 
```
$ cdk diff
```

After we read through the proposed changes we can go ahead and deploy.
```
$ cdk deploy
```

CloudFormation will now go ahead and attempt to create our infrastructure. The
magical part here is that the CDK is smart enough to add in additional
resources automatically. If we were to build this with pure CloudFormation or
Troposphere, we would have to create additional resources like a
`AWS::Lambda::Permission` to enable the SNS topic to actually invoke the Lambda
functions. The CDK has automatically done this for us in the background!


### Conclusion

The AWS CDK abstracts AWS resource definitions in a nice and ergonomic way.
Defining sets of interlinked resources has never been easier. The CDK delivers
a fully-fledged toolkit for deploying resources and requires much less
knowledge of the intricate details within CloudFormation.

Personally, I will try to use it more and more. I'd love to see support for
others languages in the future and I presume that will be the main driver for
CDK adoption among developers.

Great tool, AWS!
