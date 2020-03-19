provider "google" {
  region = "europe-west3"
  project = "${lookup(data.external.gcp_project.result, "project", "null")}"
}

data "external" "gcp_project" {
  program = [ "sh", "project-id.sh" ]
}

terraform {
  backend "gcs" {
    bucket  = "hwsh_blog-tf-state"
    prefix  = "terraform/state"
  }
}