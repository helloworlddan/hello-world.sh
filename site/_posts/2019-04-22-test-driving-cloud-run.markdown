---
layout: post
title: "Test Driving Cloud Run"
date: 2019-04-22
---

<!--markdownlint-disable-->

So today, I decided to give Google's new serverless compute offering
[Cloud Run](https://cloud.google.com/run/) a spin.

# What's Cloud Run?

Cloud Run is a brand new service that Google announced at NEXT 2019.

In short, Cloud Run lets you run stateless HTTP containers on GCP in an
effortless, production-ready way. The Cloud Run service will handle autoscaling,
high-availability and more for you and you are only charged for the actual
execution time of the running container instances.

You can run a fully serverless version on Google's clusters or enjoy the same
experience on your own GKE clusters (yes, in your private VPC) with Cloud Run on
GKE. Cloud Run itself is built on [knative](https://knative.dev) so it is almost
safe to assume that the fully serverless Cloud Run is just Cloud Run on GKE, but
running on Google's own shared GKE clusters (probably separated by k8s
namespaces). But I am blindly guessing here, so don't bet on my assumptions :)

The service is currently in public beta. At the moment, the fully serverless
version is only available in us-central1, but that is going to change when the
service leaves its beta phase.

Looking at other cloud providers, Cloud Run seems similar to
[Azure Container Instances](https://azure.microsoft.com/en-us/services/container-instances/).
Now, Azure Container Instances doesn't scale very well and it is not designed
for production workloads, but when we look at the use case in which a developer
wants to quickly bring up a containerized web service, Azure Container Instances
seems very similar to Cloud Run. The closest equivalent of Cloud Run on AWS is
[Fargate](https://aws.amazon.com/fargate/). It also provides a serverless
container execution runtime, however, Fargate comes with a lot more
configuration, flexibility, and power. Cloud Run seems to bring the best of both
Fargate and Azure Container Instances to the table. Azure Container Instances
seemed only like a toy for developers, who quickly want to show or test
something they build. Fargate can be a bit scary for engineers, who are not
exposed to it regularly. Cloud Run makes a few assumptions about your workload,
welds these assumptions into its runtime contract and provides you with a very
powerful tool for the majority of use cases on the web.

# Is it really that simple to use?

Yes, it is. It is a wonderful joy to use. I quickly stiched together the
simplest ruby web service that stills adheres to Cloud Run runtime contract and
that I could think of. It is available
[here](https://github.com/helloworlddan/cloud-run-example).

You'll need to have the beta extensions for `gcloud` installed and the Cloud Run
service needs to be enabled for your GCP project.

Of course, you need to have a container. Cloud Run's runtime contract tells you,
that the web service of your container needs to bind `0.0.0.0` and listen to the
port that is dictated by Cloud Run and given to your container as the
environment variable `$PORT`.

Here is a simple ruby source file, which defines a HTTP server using the
[sinatra](http://sinatrarb.com) framework.

```ruby
require 'sinatra'

set :bind, '0.0.0.0'
set :port, ENV["PORT"]

get '/' do
  "I am running on Cloud Run!"
end
```

Now we need to containerize the web service and push the image to
[Google Container Registry](https://cloud.google.com/container-registry/). You
can run the docker build locally (and test your web-service) or you can run the
build on [Google Cloud Build](https://cloud.google.com/cloud-build/).

Finally, it's deployment time with Cloud Run and it is _crazy_ simple to use.

```bash
gcloud beta run deploy my-service --allow-unauthenticated --image gcr.io/my-project/my-image
```

Lastly, you can find the HTTPS-secured endpoint for your new service by querying
the Cloud Run service like so:

```bash
yq r <(gcloud beta run services describe my-service) status.address.hostname
```

There you go. You have a load-balanced, highly available, extremely elastic web
service secured with TLS certificates deployed to a production-ready
environment. And you only pay when it is actually in use.

# Conclusion

I can't wait to build cool stuff on Cloud Run. Especially when I think about the
interaction with [Cloud Tasks](https://cloud.google.com/tasks/), I can see loads
of decoupled asynchronous event-driven architectures come to life.

Cloud Run makes it so incredibly easy to deploy the single most-seen use case
for cloud-native application deployments on the modern web. This significantly
lowers the barriers for developers to quickly release new services and build
awesome solutions in a matter of minutes. Well done, Google!
