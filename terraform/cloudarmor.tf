resource "google_compute_security_policy" "policy" {
  name        = "demo-security-policy"
  description = "Cloud Armor policy for App Engine behind external LB"

  # Block known malicious IPs (example)
  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["192.0.2.0/24"]
      }
    }
    description = "Block known malicious IPs (example)"
  }

  # Rate limiting: 100 requests/min per IP
  rule {
    action   = "throttle"
    priority = 2000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Rate limit: 100 req/min per IP"

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"

      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
  }

  # Block XSS and SQL injection via preconfigured WAF rules
  rule {
    action   = "deny(403)"
    priority = 3000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable') || evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Block XSS and SQL injection attempts"
  }

  # Optional: IP allowlist
  dynamic "rule" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      action   = "allow"
      priority = 500
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.allowed_ip_ranges
        }
      }
      description = "Allow only specified IP ranges"
    }
  }

  # Default: allow
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow"
  }
}
