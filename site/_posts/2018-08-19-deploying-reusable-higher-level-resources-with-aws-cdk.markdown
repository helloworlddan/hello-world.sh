---
layout: post
date: 2018-08-10
title: "Deploying reusable, higher-level resources with AWS-CDK"
---

# Introducing the AWS CDK

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
of generating additional CloudFormation resources to supply the necessary
deployment infrastructure (e.g.: a S3 bucket to hold zipped Lambda functions).

"But wait!", could you say now, "Isn't that what Troposhere is for?!". Well,
yes and no. To some extend
[Troposphere](https://github.com/cloudtools/troposphere) (and I'm sure there
are other libraries for other languages which do the same) enables developers
to define CloudFormation templates dynamically from with in a Python
environment. However, Troposphere only does half of what the AWS CDK does.
Troposphere aims more at providing a dynamic way of rendering CloudFormation
templates. It does not provide deployment tooling and it does not provide
abstraction of resources as high as the CDK.

Currently, the AWS CDK ships support for Java and TypeScript. The latter will
be transpiled into JavaScript before being rendered into CloudFormation.

# A real-world use-case

I am going to quickly lay out a real-world use-case to demonstrate usage of the
AWS CDK.

A recent project was about governing a large corporate AWS estate. The top two
focuses of the project were governance of AWS accounts for multiple development
teams and managing additional development tools on top of the AWS estate.
Requirements for heavy automation led us to build an Account Vending Machine
(AVM) that would automatically configure AWS accounts for development teams. To
further automate our AVM, it would also need to be able to configure the
development tools. For example: If a new development team is formed, the AVM
would automatically create AWS accounts for the team. Furthermore, the AVM
needed to trigger off some other automation tool to configure applications like
[Slack](https://slack.com) to setup some defaults inside of it (e.g.: default
channels).

Our application was holding the layout of the organization in some database and
every time something in the organization configuration would change (e.g.: a new
development team gets added), the automation had to run off and do it's job.

The following shows an architecture that relies on SNS and Lambda (or
StepFunctions) to do run a multitude of configuration tasks. Configurations
are divided up into two categories: Organization configuration is holding
configuration that is application-agnostic, like the layout of all development
teams. The second configuration category would be application-specific. This
could be something like setting up federation for an application.

![Use-case architecture layout](/assets/images/deploying-reusable-higher-level-resources/arch.png)

As you can see, updates to configuration are being pushed to SNS topics.
Application-agnostic updates are fanned out to all service configurators,
whereas application-specific updates are only pushed to a specific
configurator.

It shouldn't be hard to detect the obvious pattern in the architecture.

# Let's get started

I am assuming that you have `npm` installed.

Let's add some node packages first!

```bash
# NOTE This will only add a few CDK modules. To add specific modules, run:
# npm i -g @aws-cdk/aws-lambda
npm i -g aws-cdk
```

We are going to setup a project directory and initialize it with the CDK. I am
choosing TypeScript to build this project.

```bash
mkdir cdk-setup-service
cd cdk-setup-service
# Initialize the project. NOTE: you could also use --language java
cdk init app --language typescript
```

That's it! The CDK will auto-generate some code that would setup an SNS topic
and an SQS queue.

# Building our solution

I am creating a class that aims at encapsulating the pattern that is obviously
repeating in the architecture. We need one Lambda function per application to
compute changes and updates to our organizational layout and one Lambda function
to process all the application-specific updates. Additionally, we need to setup
a bunch of SNS topics and subscriptions to do all the event-based plumbing to
make the whole thing work.

The following TypeScript class definition acts like an umbrella, holding all
the required resources to setup service configurators for one application. I am
going to save it to `bin/cdk-service-configurator.ts`

```ts
import * as path from 'path';

import sns = require('@aws-cdk/aws-sns');
import lambda = require('@aws-cdk/aws-lambda');
import cdk = require('@aws-cdk/cdk');

export class CdkServiceConfigurator {

  parentStack: cdk.Stack;
  applicationName: string;
  lambdaCodePath: string;

  organizationUpdater: lambda.Lambda;
  applicationUpdater: lambda.Lambda;

  applicationUpdatesTopic: sns.Topic;

  constructor(stack: cdk.Stack, name: string) {
    this.parentStack = stack;
    this.applicationName = name;
    this.lambdaCodePath = path.join(__dirname, 'lambda', this.applicationName);

    this.applicationUpdatesTopic = new sns.Topic(
      this.parentStack,
      this.applicationName.concat('ApplicationUpdatesTopic')
    );

    this.organizationUpdater = new lambda.Lambda(
      this.parentStack,
      this.applicationName.concat('OrganizationUpdater'),
      {
        code: lambda.LambdaCode.directory(
          path.join(this.lambdaCodePath, 'organization-update-handler')
        ),
        handler: 'index.handler',
        runtime: lambda.LambdaRuntime.Python27
      });
    this.applicationUpdater = new lambda.Lambda(
      this.parentStack,
      this.applicationName.concat('ApplicationUpdater'),
      {
        code: lambda.LambdaCode.directory(
          path.join(this.lambdaCodePath, 'application-update-handler')
        ),
        handler: 'index.handler',
        runtime: lambda.LambdaRuntime.Python27
      });

    this.applicationUpdatesTopic.subscribeLambda(this.applicationUpdater);
  }
}
```

Nice. The service configurator can now be instantiated for every application
that requires configuration. Note how the service configurator expects to find
the Python code for it's Lambda functions in a very specific directory.

The current layout of the project directory looks like this (node_modules
redacted for obvious reasons):

{% highlight bash %}
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
{% endhighlight %}

Let's change the auto-generated file `bin/cdk-setup-service.ts` so it
references our service configurator. We are also going to instantiate it for
the application Slack.

```ts
#!/usr/bin/env node
import sns = require('@aws-cdk/aws-sns');
import cdk = require('@aws-cdk/cdk');
import { CdkServiceConfigurator } from './cdk-service-configurator'

class CdkSetupServiceStack extends cdk.Stack {
  constructor(parent: cdk.App, name: string, props?: cdk.StackProps) {
    super(parent, name, props);

    // Setup topic for application-agnostic updates to organization layout
    const organizationUpdatesTopic = new sns.Topic(this, 'OrganizationUpdatesTopic');

    // Setup service configurator for Slack application
    const slackConfigurator = new CdkServiceConfigurator(this, 'Slack');

    // Make Slack updater listen on global organization updates
    organizationUpdatesTopic.subscribeLambda(slackConfigurator.organizationUpdater);

  }
}

const app = new cdk.App(process.argv);

new CdkSetupServiceStack(app, 'CdkSetupServiceStack');

process.stdout.write(app.run());
```

Okay! That should be it! `bin/cdk-setup-service.ts` defines a class, which
inherits from cdk.Stack and instantiates a global topic for
application-agnostic updates and an instance of the service configurator for
Slack.

# Deploying to the cloud

Let's get cracking and deploy our project to the cloud. After we make sure that
our current environment has valid AWS credentials, we can get to work.

Firstly, we need to transpile our TypeScript code to JavaScript.

```bash
npm run build
```

Okay, now since our deployment requires the usage of assets (zipped Lambda
function code), we need to instruct the CDK to bootstrap our environment.
This will create an additional stack containing a bucket to save our Lambda
code packages in.

```bash
cdk bootstrap
```

Now we can use the CDK to compute a diff between the resources that are already
deployed and the changes that the CDK would hand to CloudFormation to deploy
now. Since we haven't deployed anything yet, the first diff will contain all
the defined resources.

```bash
cdk diff
```

After we read through the proposed changes we can go ahead and deploy.

```bash
cdk deploy
```

CloudFormation will now attempt to create our infrastructure. The magical part
here is that the CDK is smart enough to add in additional resources
automatically. If we were to build this with pure CloudFormation or
Troposphere, we would have to create additional resources like a
`AWS::Lambda::Permission` to enable the SNS topic to actually invoke the Lambda
functions. The CDK has automatically done this for us in the background! To
verify this, check the output of `cdk diff` again.

# Conclusion

The AWS CDK abstracts AWS resource definitions in a nice and ergonomic way.
Defining sets of interlinked resources has never been easier. The CDK delivers
a complete toolkit for deploying resources and requires much less
knowledge of the intricate details of CloudFormation.

Personally, I will try to use it more often. I'd love to see support for other
languages in the future and I presume that language support will be the main
driver for CDK adoption among developers.

Great tool, AWS!
