resource "google_service_account" "default" {
  project      = local.project
  account_id   = "blog-sa"
  display_name = "Blog Service Account"
}

resource "google_cloud_run_service" "default" {
  provider = google-beta
  project  = local.project
  name     = "${local.prefix}-service"
  location = local.region

  template {
    spec {
      service_account_name = google_service_account.default.email
      containers {
        image = "gcr.io/${local.project}/hwsh"
        resources {
          limits = {
            cpu    = "1000m"
            memory = "128Mi"
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
  project  = local.project
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
  project  = local.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

resource "google_cloudbuild_trigger" "default" {
  project  = local.project
  provider = google-beta
  github {
    name  = local.repo
    owner = local.repo_owner
    push {
      branch = local.branch
    }
  }
  substitutions = {
    _REGION      = local.region
  }
  name        = "${local.prefix}-trigger"
  description = "Build pipeline for ${local.prefix}-service"
  filename    = "container/cloudbuild.yaml"
}

# Allow Cloud Build to bind SA
resource "google_service_account_iam_member" "default-sa-user" {
  provider           = google-beta
  service_account_id = google_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com"
}


resource "google_project_iam_member" "build-build" {
  provider           = google-beta
  project            = local.project
  role               = "roles/cloudbuild.serviceAgent"
  member             = "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com"
}