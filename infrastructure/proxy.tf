resource "google_compute_global_address" "default" {
  project = local.project
  name = "${local.prefix}-proxy-ip"
}

resource "google_compute_global_forwarding_rule" "https" {
  project = local.project
  name = "${local.prefix}-https-frontend"
  target = google_compute_target_https_proxy.https.self_link
  port_range = "443"
  ip_address = google_compute_global_address.default.address
}

resource "google_compute_global_forwarding_rule" "http" {
  project = local.project
  name = "${local.prefix}-http-frontend"
  target = google_compute_target_http_proxy.http.self_link
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

resource "google_compute_target_https_proxy" "https" {
  project = local.project
  name = "${local.prefix}-https-proxy"
  url_map = google_compute_url_map.https.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.self_link
  ]
}

resource "google_compute_target_http_proxy" "http" {
  project = local.project
  name = "${local.prefix}-http-proxy"
  url_map = google_compute_url_map.http.self_link
}

resource "google_compute_url_map" "https" {
  project = local.project
  name = "${local.prefix}-https-proxy"
  default_service = google_compute_backend_bucket.default.self_link
}

resource "google_compute_url_map" "http" {
  project = local.project
  name = "${local.prefix}-http-proxy"
  default_service = google_compute_backend_bucket.default.self_link
}

resource "google_compute_backend_bucket" "default" {
  project = local.project
  name = "${local.prefix}-backend"
  bucket_name = google_storage_bucket.default.name
  enable_cdn  = true
}

output "proxy_ip" {
  value = google_compute_global_address.default.address
}
