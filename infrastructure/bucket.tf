resource "google_storage_bucket" "blog_bucket" {
  name          = "hwsh_blog"
  location      = "EU"
  force_destroy = true

  bucket_policy_only = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["http://hello-world.sh"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}