terraform {
  backend "gcs" {
    bucket = "hwsh-blog-admin"
    prefix = "terraform/state"
  }
}

provider "google-beta" {
  region = local.region
}

provider "google" {
  region = local.region
}
