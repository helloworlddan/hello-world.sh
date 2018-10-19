+++ 
draft = false
date = 2018-10-19T14:00:00+02:00
title = "CloudFormation Macros"
slug = "" 
tags = []
categories = ['AWS', 'CloudFormation', 'Macros', 'IaC', 'Python', 'Lambda', 'SSM']
+++

### Introduction

A little while ago, AWS released a Cloudformation feature, which enables
developers to extend the flexibility of Cloudformation themselves.
[Cloudformation
Macros](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-macros.html)
can be used to run custom 'Fn::Transform' operations on Cloudformation
templates using AWS Lambda. Furthermore, since it is using Lambda, these macros
can run any arbitrary code while doing so.

### Setup

As a semi-useful example I created a passphrase generator macro, which creates
a random passphrase, stores it in SSM and then injects the passphrase into the
resource definition.

Cloudformation Macros are Cloudformation resources as well. They are backed by
a Lambda function, which needs to return a specifically structured JSON
payload.

{{< gist daniceman 3d9d2128fedf59e9f5074a5359fae9fa >}}

Note the new Cloudformation resource `AWS::Cloudformation::Macro`, which makes
the Lambda function accessible from other CloudFormation templates.

The macro can be deployed like this:
```
aws cloudformation create-stack \
      --stack-name macro-password-generator \
      --capabilities CAPABILITY_NAMED_IAM \
      --template-body file://password-generator.yaml
```

That's it! The macro can now be used from inside of other templates!

### Usage

The newly created macro for automatic generation of passphrases can now be
used. A common example could be the provisioning of an RDS database instance.
Setting the password for the user can be insecure, if it is not handled
correctly. If you were to put the password plain into the Cloudformation
template, the template would still be uploaded to Cloudformation (that is S3)
and could still be viewed or retrieved from the Cloudformation console or
CLI. A better method of setting passwords would be to create a passphrase
first, store it securely inside of SSM and then using [dynamic
references](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html)
inside of the Cloudformation template. But you would still need to setup the
passphrase in SSM first.

Here is a very simple resource definition of a small RDS instance using our
newly generated password generator macro.

{{< gist daniceman 909393a0d253872d1a1729a1b1487291 >}}

This is using the same intrinsic 'Fn::Transform' function that powers other
Cloudformation features, like `AWS::Include`.

You can deploy the RDS instance by instructing Cloudformation to generate a
ChangeSet like so:

```
aws cloudformation deploy \
      --stack-name database \
      --template-file use-password-generator.yaml
```

That's it. The newly generated password to the RDS master user should be the
value behind `/rds/passwords/dan` in the SSM Parameter Store. 
