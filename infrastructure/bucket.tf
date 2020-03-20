resource "google_storage_bucket" "default" {
  project = local.project
  name = local.prefix
  location = "EU"
  force_destroy = true

  bucket_policy_only = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin = ["https://${local.domain}"]
    method = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_storage_bucket.default.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}

output "bucket" {
  value = google_storage_bucket.default.name
}