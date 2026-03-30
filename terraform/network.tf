resource "google_compute_network" "vpc" {
  name                    = "demo-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "connector_subnet" {
  name          = "demo-vpc-connector-subnet"
  ip_cidr_range = "10.8.0.0/28"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Private IP range for Cloud SQL peering
resource "google_compute_global_address" "sql_private_ip_range" {
  name          = "demo-sql-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Private services access peering
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_private_ip_range.name]
  depends_on              = [google_project_service.apis]
}

# VPC Access Connector for App Engine -> Cloud SQL
resource "google_vpc_access_connector" "connector" {
  name   = "demo-vpc-connector"
  region = var.region

  subnet {
    name = google_compute_subnetwork.connector_subnet.name
  }

  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3

  depends_on = [google_project_service.apis]
}
