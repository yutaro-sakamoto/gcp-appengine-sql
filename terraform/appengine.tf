resource "google_app_engine_application" "app" {
  project     = var.project_id
  location_id = var.region == "us-central1" ? "us-central" : var.region
  depends_on  = [google_project_service.apis]
}

resource "google_storage_bucket" "app_bucket" {
  name     = "${var.project_id}-app-deploy"
  location = var.region

  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [google_project_service.apis]
}

resource "google_storage_bucket_object" "app_zip" {
  name   = "app-v1.zip"
  bucket = google_storage_bucket.app_bucket.name
  source = "${path.module}/../app/app.zip"
}

resource "google_app_engine_flexible_app_version" "app_v1" {
  version_id = "v1"
  project    = var.project_id
  service    = "default"
  runtime    = "python"

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/${google_storage_bucket.app_bucket.name}/${google_storage_bucket_object.app_zip.name}"
    }
  }

  entrypoint {
    shell = "gunicorn -b :$PORT main:app"
  }

  env_variables = {
    DB_HOST     = google_sql_database_instance.postgres.private_ip_address
    DB_NAME     = google_sql_database.demo_db.name
    DB_USER     = google_sql_user.demo_user.name
    DB_PASSWORD = var.db_password
  }

  vpc_access_connector {
    name = google_vpc_access_connector.connector.id
  }

  automatic_scaling {
    min_total_instances = 1
    max_total_instances = 4
    cool_down_period    = "120s"

    cpu_utilization {
      target_utilization = 0.6
    }
  }

  liveness_check {
    path = "/health"
  }

  readiness_check {
    path = "/health"
  }

  noop_on_destroy = true

  depends_on = [google_app_engine_application.app]
}
