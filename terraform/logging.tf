# BigQuery dataset for log storage
resource "google_bigquery_dataset" "logs" {
  dataset_id    = "appengine_logs"
  friendly_name = "App Engine Access Logs"
  description   = "App Engine request logs and Cloud Armor logs for admin analysis"
  location      = var.region

  default_table_expiration_ms = 7776000000 # 90 days

  labels = {
    environment = "demo"
  }
}

# Log Router sink: App Engine + LB + Cloud Armor logs -> BigQuery
resource "google_logging_project_sink" "appengine_sink" {
  name        = "demo-appengine-log-sink"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs.dataset_id}"

  filter = <<-EOT
    resource.type = "gae_app"
    OR resource.type = "http_load_balancer"
  EOT

  bigquery_options {
    use_partitioned_tables = true
  }

  unique_writer_identity = true
}

# Grant log sink write access to BigQuery
resource "google_bigquery_dataset_iam_member" "log_writer" {
  dataset_id = google_bigquery_dataset.logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.appengine_sink.writer_identity
}
