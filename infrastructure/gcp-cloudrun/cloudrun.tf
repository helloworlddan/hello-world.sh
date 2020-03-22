resource "google_cloud_run_service" "default" {
  provider = google-beta
  project = local.project
  name     = "${local.prefix}-service"
  location = local.region

  template {
    metadata {
      namespace = local.project
    }
    spec {
      containers {
        image = "gcr.io/${local.project}/hwsh"
        resources {
          limits = {
            cpu = "1000m"
            memory = "256M"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_domain_mapping" "default" {
  project = local.project
  location = local.region
  name     = local.domain

  metadata {
    namespace = local.project
  }

  spec {
    route_name = google_cloud_run_service.default.name
  }
}

resource "google_cloud_run_service_iam_binding" "public" {
  location = local.region
  project = local.project
  service = google_cloud_run_service.default.name
  role = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

output "dns_records" {
  value = [
    for record in google_cloud_run_domain_mapping.default.status[0].resource_records:
      lookup(record, "rrdata", "none")
  ]
}