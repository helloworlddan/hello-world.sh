+++ 
draft = true
date = 2018-08-12T17:00:00+02:00
title = "Hello-World.sh"
slug = "" 
tags = []
categories = ["Site Hosting", "AWS", "Route53", "S3", "CloudFront", "ACM"]
+++

### Introduction

Yesterday, I was asked about the setup behind hello-world.sh and as I caught
myself drifting off into details I thought to myself: Why not explain it in
depth right here? So this is what this post is about: Setting up a
highly-scalable site, obtaining your own cool domain name, have all content
cached at the edge for milli-second latency, have our own Email domain and
mailboxes, encrypt all content in transit with validated TLS certificates and
don't spend tons of money, because it's all serverless. 

### Domain Registration

First of all we need a domain. Route53 comes with super neat functionality to
register domains. To be honest, I actually spend quite a lot of time trying
loads and loads of possible domain names. You can come up with quite a lot of
unique ideas given the recent additions in TLDs. I was barely able to believe
that something like hello-world.sh wasn't taken yet. After providing the
necessary legal information (for `whois` calls and such), I was able to directly
use my newly purchased domain as a hosted zone in Route53.

It is probably a wise idea to spend quite a lot of time choosing your domain
name. In the end you will spend the most money on domain registration. The rest
of the architecture is really, really comparativly inexpensive. Bringing and
existing domain along and importing it into Route53 is also possible of course.

### Infrastructure




### Oh yeah, let's also do mail

In order to have mail infrastructure for @hello-world.sh, I quickly setup AWS
WorkMail to do the job. WorkMail lets you create a highly-scalable Personal
Information Management (PIM) suite with mail, calendar and contacts
functionality. It even comes with it's own web apps to easily access your
accounts. After setting up WorkMail I chose to configure the service to also be
able to use my newly-purchased domain. This is done by [simply setting up some
record
sets](https://docs.aws.amazon.com/workmail/latest/adminguide/add_domain.html)
in your hosted zone in Route53.

That's it! The process less than 10 minutes!

### Code (for you to reuse)
