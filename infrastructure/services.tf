resource "google_project_service" "compute_service" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
}