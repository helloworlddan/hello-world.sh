resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  project = local.project
  name = "${local.prefix}-certificate"

  managed {
    domains = ["${local.domain}."]
  }
}