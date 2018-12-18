+++
draft = false
date = 2018-08-12T17:00:00+02:00
title = "Hello-World.sh"
slug = ""
tags = []
categories = ["Site Hosting", "AWS", "Route 53", "S3", "CloudFront", "ACM", "serverless"]
+++

### Introduction

Yesterday, I was asked about the setup behind hello-world.sh and as I caught
myself drifting off into details I thought to myself: Why not explain it in
depth right here?

So this is what this post is about: Setting up a highly-scalable site,
obtaining your own cool domain name, have all content cached at the edge for
millisecond latency, have your own Email domain and mailboxes, encrypt all
content in transit with validated TLS certificates and don't spend tons of
money, because it's all serverless.

### Domain Registration

First of all we need a domain. Route 53 comes with super neat functionality to
register domains. To be honest, I actually spent quite a lot of time trying
loads and loads of possible domain names. You can come up with quite a lot of
unique ideas given the recent additions in TLDs. I was barely able to believe
that something like hello-world.sh wasn't taken yet. I was able to directly
use my newly purchased domain as a hosted zone in Route 53 in a matter of
minutes.

It is probably a wise idea to spend quite a lot of time choosing your domain
name. In the end you will spend the most money on domain registration. The rest
of the architecture is comparatively inexpensive. Bringing an existing domain
along and importing it into Route 53 is also possible.

### Infrastructure

Okay, let's look at what I wanted for hello-world.sh and how I actually built
it. A quick glance at my requirements for the site reveals that there is no
black magic involved. It's fairly simple and straight forward in its
functional requirements. However, non-functionally speaking, it absolutely
needs to be state-of-the-art.

I wanted hello-world.sh to:

* be globally retrievable with sub-second latency through a CDN
* have its traffic completely encrypted with 256-bit RSA
* have a proper trust validation with recognised root CAs
* be as highly available as possible
* be completely automated and
* cost very little money

Now, this might seem like a pretty tall order, but thankfully, AWS has made
this incredibly easy.

Okay, lets weld some building blocks together and visualize them:

![Architecture overview](/images/hello-world.sh/arch.png)

Storage for hosting the content of the site is handled by an S3 bucket with
static website hosting functionality enabled (revolutionary... who would have
thought?!). CloudFront is used to do edge-caching of the content. Now, AWS has
builtin functionality to limit access to the underlying bucket to the
CloudFront distribution. By using this functionality, we don't need to make our
bucket publicly accessible on the open internet. The only way of accessing its
contents is through CloudFront. To make this work, we also need to provision a
so-called Origin Access Identity (OAI) during deployment. OAIs come with a
unique, canonical user identity to access S3. IAM and (more importantly) S3
Bucket Policies are aware of this identity and they can evaluate permissions
just as with any other prinicipal. This means we can limit access to our bucket
to just a very specific requester: CloudFront.

We are also setting up a DNS record in Route 53 to point the apex of our domain
at the unique FQDN of the CloudFront distribution. To do this, we are making
use of the AWS-internal ALIAS functionality to resolve our CloudFront IPs.
Interestingly, we need to specify the HostedZoneId of the CloudFront service,
which is 'Z2FDTNDATAQYW2'.  This is the HostedZoneId for the hosted zone
'cloudfront.net.', which holds all the record sets to the various CloudFront
distribution in AWS.

It is important to understand that the static web-site content needs to be
tuned to properly do redirecting to content. It is a good idea to try and
always use relative URLs. Another important limitation is that CloudFront can
only default to an index.html in the root of the distribution. Don't use links
to sub-paths of the content directory. Use links to the full object path
instead. Most static web-site generators, like [Hugo](https://gohugo.io/), can
be configured to do so automatically.

Here is the CloudFormation template to deploy all the infrastructure I need for
hello-world.sh:

{{< gist helloworlddan 1e3283b6fede5e535efed87d5a087470 >}}

It is not that much! We are just feeding in the name of our domain and a
previously created certificate in us-east-1. It has to be in us-east-1 to be
used as a global custom certificate for CloudFront.

### Oh yeah, let's also do mail

In order to have mail infrastructure for @hello-world.sh, I quickly setup AWS
WorkMail to do the job. WorkMail lets you create a highly-scalable Personal
Information Management (PIM) suite with mail, calendar and contacts
functionality. It even comes with it's own web apps to easily access your
accounts. After setting up WorkMail I chose to configure the service to also be
able to use my newly-purchased domain. This is done by [simply setting up some
record
sets](https://docs.aws.amazon.com/workmail/latest/adminguide/add_domain.html)
in my hosted zone in Route 53.

That's it! The process of setting up mail was less than 15 minutes!

### Code (for you to reuse)

Initial requirements don't seem like that much of a tall order anymore. AWS has
made it incredibly easy and accessible for everyone to setup a secure,
state-of-the-art static web-site, that is ready to scale to millions of
viewers.

The complete code to this page (content & infrastructure) is
[here](https://github.com/helloworlddan/hello-world.sh).

And yes: it has a hello-world.sh file in it.
