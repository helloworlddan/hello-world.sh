resource "google_compute_global_forwarding_rule" "default" {
  project = local.project
  name = "${local.prefix}-frontend"
  target = google_compute_target_https_proxy.default.self_link
  port_range = "443"
}

resource "google_compute_target_https_proxy" "default" {
  project = local.project
  name = "${local.prefix}-proxy"
  url_map = google_compute_url_map.default.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.self_link
  ]
}

resource "google_compute_url_map" "default" {
  project = local.project
  name = "${local.prefix}-proxy"
  default_service = google_compute_backend_bucket.default.self_link
}

resource "google_compute_backend_bucket" "default" {
  project = local.project
  name = "${local.prefix}-backend"
  bucket_name = google_storage_bucket.default.name
  enable_cdn  = true
}
