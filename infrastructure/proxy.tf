resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  name = "${local.prefix}-certificate"

  managed {
    domains = ["blog.hello-world.sh."]
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "${local.prefix}-frontend"
  target     = google_compute_target_https_proxy.default.self_link
  port_range = "443"
}

resource "google_compute_target_https_proxy" "default" {
  name             = "${local.prefix}-proxy"
  url_map          = google_compute_url_map.default.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.self_link
  ]
}

resource "google_compute_url_map" "default" {
  name        = "${local.prefix}-proxy"
  default_service = google_compute_backend_bucket.default.self_link
}

resource "google_compute_backend_bucket" "default" {
  name        = "${local.prefix}-backend"
  bucket_name = google_storage_bucket.default.name
  enable_cdn  = true
}
