resource "google_cloud_run_service" "default" {
  project = local.project
  name     = "{local.prefix}-service"
  location = local.region

  template {
    metadata {
      namespace = local.project
    }
    spec {
      containers [
        image = "gcr.io/${local.project}/hwsh"
      ]
    }
  }
}

resource "google_cloud_run_service_iam_member" "public" {
  project = local.project
  location = google_cloud_run_service.default.location
  service = google_cloud_run_service.default.name
  role = "roles/run.Invoker"
  member = "allUsers"
}
