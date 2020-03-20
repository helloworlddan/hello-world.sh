terraform {
  backend "gcs" {
    bucket  = "hwsh_blog-tf-state"
    prefix  = "terraform/state"
  }
}

provider "google-beta" {
  region = local.region
}

provider "google" {
  region = local.region
}

data "external" "project" {
  program = ["sh", "project-id.sh"]
}
