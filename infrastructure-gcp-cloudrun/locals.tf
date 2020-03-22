locals {
  prefix = "hwsh-blog"
  region = "europe-west4"
  project = lookup(data.external.project.result, "project", "null")
  domain = "hello-world.sh"
}