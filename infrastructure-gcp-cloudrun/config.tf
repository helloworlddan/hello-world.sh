terraform {
  backend "gcs" {
    bucket  = "hwsh-blog-admin"
    prefix  = "terraform-cr/state"
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
