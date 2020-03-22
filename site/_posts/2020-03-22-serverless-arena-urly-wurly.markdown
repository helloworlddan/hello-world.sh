---
layout: post
title: "Serverless Arena: Urly Wurly"
coauthor:
  fullname: "Mahindra Kumar"
date: 2019-12-11
---

After nine years of URL shortening glory, Google discontinued the famous goo.gl service earlier this year. This gave birth to the idea of creating and operating our own URL shortening service at Cloudreach and ended with the first installment of the Serverless Arena. You might ask what Serverless Arena is? As part of Cloudreach internal Serverless Community, we launched a simple competition: to create a URL Shortener using your favourite Cloud Provider and only using serverless technology.  For lack of a better title, we called the competition 'Serverless Arena'.

Numerous brave gladiators gathered in the arena, each designing and building their own vision of a perfect serverless URL shortening service, battle-testing it in relentless competition. Their efforts were judged by a merciless jury until one victorious service emerged...Urly Wurly. Yup, that’s right. You are looking at the winner. 🎉

Urly Wurly is a serverless URL shortening service built on GCP. It uses Google’s brand new Cloud Run service at its heart. Urly Wurly is also the name of the team that created it. The name derives from the idea of taking a really long URL, putting it in a whirling magic machine and ending up with something short and snappy. As you would expect, the team ended up spending most of its time designing a suitable logo that would adequately convey this idea. The team put its creative genius to the test and, ultimately, came up with the following masterpiece:

<img src="/assets/images/serverless-arena-urly-wurly/logo.png" alt="Urly-Wurly Logo" width="200"/>

Pretty, isn’t it?

With this blog post, we want to open source Urly Wurly, in hopes that you can all benefit from it, either to get your own personalised URL shortener or just to see how we have implemented it in a way which is 100% serverless. You can head over to [Github](https://github.com/cloudreach/urly-wurly) and fork the repository or just have a look at ours.

# What is Urly Wurly?

Essentially, Urly Wurly is a web service that performs two major operations: It can accept a long URL, store it and return a very short link within its own domain. Secondly, it can be invoked with a previously shortened URL and redirect the caller to the long, previously-stored URL.

This functionality can be consumed via a number of different frontends, such as:

* Straight from the browser. It will return a tiny web application to get all of your shortening needs done. 

* From the CLI. Urly Wurly has a published [ruby gem](https://rubygems.org/gems/wurly), which can be used to shorten URLs. Alternatively, cURL, wget or any other HTTP client can be used to access the service endpoint directly.

* Using a Chrome extension. We have created a Chrome extension, which we’ll put a one-click shortening button in Chrome’s toolbar to get the job done. We are currently still looking at publishing the extension on the Chrome Web Store.

* Directly from Slack using [Slash Commands](https://api.slack.com/tutorials/your-first-slash-command). The Urly Wurly service has a built-in call to support these commands from slack. 

# What is Under the Hood?

Urly Wurly's backend is a web server built in GoLang. The application gets packaged as a Docker container which runs on GCP Cloud Run. It is using the fully-managed version of [Cloud Run](https://cloud.google.com/run/), hence it has to be considered serverless. Cloud Run has loads of amazing features and best practices built-in, while the service is able to hide the intricate complexities of the underlying virtual machines and Kubernetes clusters from the consumer. With smooth horizontal scaling, Cloud Run will deploy new revisions of the service containers in a blue-green fashion with automatic tests and rollback built-in.

Integrated logging, monitoring, TLS certificates and offloading, load-balancing, blue-green deployments, health checks and 0 to near-infinite scale is all part of GCP Cloud Run and almost completely invisible to us. This is amazing because we consider this to be undifferentiated heavy-lifting. #serverlessrocks

The web service container is completely stateless. All application state is stored on [Google Cloud Storage](https://cloud.google.com/storage/) (GCS). We have chosen GCS for a number of reasons. GCS is serverless and it is incredibly cheap. Due to the nature of how we use it, we optimize our usage of GCS from the get-go: Long URLs are stored as single GCS objects. The short, URL-friendly keys for each object are derived from base58-encoded checksums (crc32) of the stored URLs. Because GCS [determines partition placement](https://cloud.google.com/storage/docs/request-rate) according to the names of object keys and because our key names are fairly random, this makes up for [optimal GCS throughput](https://cloud.google.com/storage/docs/best-practices) due to evenly spread keys across GCS partitions. It also helps with reusing already stored URLs, as they would have the same key names and would only be stored once. GCS buckets also come with a great default monitoring configuration in Stackdriver. We can easily determine the total number of stored links by examining the number of objects in the bucket. At a later stage, we might make use of additional features. Lifecycle management of objects in the bucket might come in handy.

Here is an overview of how the underlying infrastructure components interact with each other.

![Urly-Wurly Architecture](/assets/images/serverless-arena-urly-wurly/arch.png)

# How do we develop it?

The infrastructure of Urly Wurly is expressed in TypeScript, which will be interpreted and executed as a number of Terraform-based API calls to GCP by [Pulumi](https://www.pulumi.com/). This gives us a nice high-level programming interface for our infrastructure. Pulumi stores the Terraform state on its own web service, which eliminates another potential headache. Next to the Cloud Run services and the GCS bucket, Pulumi also creates some supporting infrastructure, like GCP Cloud Build triggers and pipelines, DNS zones and IAM bindings. It is important to mention that we were unable to define our complete infrastructure in Pulumi/Terraform because of the fact that some of the needed resources are simply not yet supported by Terraform/Pulumi.

Pushes to the master branch will trigger automated integration builds on [GCP Cloud Build](https://cloud.google.com/cloud-build) and resulting docker image artifacts are stored on [GCP Container Registry](https://cloud.google.com/container-registry/). GCP Cloud Build will then assume the service account of GCP Compute Engine to initiate a deployment on GCP Cloud Run. If the new deployment artifact passes health checks, then traffic will be re-routed to the new deployment (blue/green). Pushes to develop branches also get integrated and deployed in a separate environment.

# Why is it the best service?

It has got the finest Internet plumbing which can scale infinitely (virtually) with zero downtime deployments at almost no costs. It uses the best in class serverless containers which can be ported to any cloud provider you like. Azure Container Instances or Amazon Web Services Fargate come to mind as they are compatible with minimal portation efforts. One also has to consider the mind-blowing beauty of Urly Wurly’s handcrafted logo :D

# What is our conclusion?

GCP tooling is amazing! You can get started really quickly. We have mostly been interacting with fairly new services (Cloud Build, Cloud Run). Cloud Build is an absolute pleasure to work with. It even has a built-in feature that allows you to quickly tarball the contents of your workspace, upload it to GCS, and run it as a build on Cloud Build (all in one single gcloud command). This allows engineers to quickly integrate their work remotely (you might even deploy it on a separate Cloud Run deployment) and verify the changes before committing it to source control (when the actual team pipelines are triggered). CI/CD seems to get a little cousin: Personal CI, Personal CD.
