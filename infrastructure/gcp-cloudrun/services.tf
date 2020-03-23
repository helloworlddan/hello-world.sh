resource "google_project_service" "cloudrun" {
  project = local.project
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "registry" {
  project = local.project
  service = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project = local.project
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudprofiler" {
  project = local.project
  service = "cloudprofiler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudtrace" {
  project = local.project
  service = "cloudtrace.googleapis.com"
  disable_on_destroy = false
}