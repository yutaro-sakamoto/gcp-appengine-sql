# Static global IP
resource "google_compute_global_address" "lb_ip" {
  name = "demo-lb-ip"
}

# Serverless NEG pointing to App Engine
resource "google_compute_region_network_endpoint_group" "appengine_neg" {
  name                  = "demo-appengine-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  app_engine {
    service = google_app_engine_flexible_app_version.app_v1.service
    version = google_app_engine_flexible_app_version.app_v1.version_id
  }
}

# Backend service with Cloud Armor and logging
resource "google_compute_backend_service" "appengine_backend" {
  name                  = "demo-appengine-backend"
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.policy.id

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  backend {
    group = google_compute_region_network_endpoint_group.appengine_neg.id
  }
}

# URL Map
resource "google_compute_url_map" "url_map" {
  name            = "demo-url-map"
  default_service = google_compute_backend_service.appengine_backend.id
}

# --- HTTPS (domain required) ---

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  count = var.domain != "" ? 1 : 0
  name  = "demo-ssl-cert"

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  count   = var.domain != "" ? 1 : 0
  name    = "demo-https-proxy"
  url_map = google_compute_url_map.url_map.id

  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert[0].id]
}

resource "google_compute_global_forwarding_rule" "https_forwarding" {
  count                 = var.domain != "" ? 1 : 0
  name                  = "demo-https-forwarding"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy[0].id
  ip_address            = google_compute_global_address.lb_ip.id
}

# --- HTTP (always created) ---

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "demo-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding" {
  name                  = "demo-http-forwarding"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  ip_address            = google_compute_global_address.lb_ip.id
}
