output "load_balancer_ip" {
  description = "Public IP of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "appengine_url" {
  description = "Direct App Engine URL (bypasses Cloud Armor)"
  value       = "https://${var.project_id}.appspot.com"
}

output "cloud_sql_private_ip" {
  description = "Private IP of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "bigquery_log_dataset" {
  description = "BigQuery dataset for log analysis"
  value       = "${var.project_id}.appengine_logs"
}

output "log_query_example" {
  description = "Example BigQuery query to search access logs"
  value       = <<-EOT
    -- Recent requests
    SELECT timestamp, httpRequest.requestUrl, httpRequest.status, httpRequest.remoteIp
    FROM `${var.project_id}.appengine_logs.gae_app_*`
    WHERE timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
    ORDER BY timestamp DESC
    LIMIT 100;

    -- Requests blocked by Cloud Armor
    SELECT timestamp, httpRequest.remoteIp, httpRequest.requestUrl,
           jsonPayload.enforcedSecurityPolicy.outcome
    FROM `${var.project_id}.appengine_logs.http_load_balancer_*`
    WHERE jsonPayload.enforcedSecurityPolicy.outcome = "DENY"
    ORDER BY timestamp DESC;

    -- Top blocked IPs
    SELECT httpRequest.remoteIp, COUNT(*) as blocked_count
    FROM `${var.project_id}.appengine_logs.http_load_balancer_*`
    WHERE jsonPayload.statusDetails = "rate_based_ban"
    GROUP BY httpRequest.remoteIp
    ORDER BY blocked_count DESC
    LIMIT 20;
  EOT
}
