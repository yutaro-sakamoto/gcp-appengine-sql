resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "postgres" {
  name             = "demo-postgres-${random_id.db_suffix.hex}"
  region           = var.region
  database_version = "POSTGRES_15"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.self_link
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled = false
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "demo_db" {
  name     = "demo_db"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "demo_user" {
  name     = "demo_user"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
