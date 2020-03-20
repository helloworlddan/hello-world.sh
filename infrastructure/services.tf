resource "google_project_service" "compute_service" {
  project = local.project
  service = "compute.googleapis.com"
  disable_on_destroy = false
}