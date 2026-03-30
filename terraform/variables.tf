variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "db_password" {
  description = "Cloud SQL user password"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain name for SSL certificate (leave empty for HTTP-only demo)"
  type        = string
  default     = ""
}

variable "allowed_ip_ranges" {
  description = "IP CIDR ranges allowed through Cloud Armor (empty = all allowed)"
  type        = list(string)
  default     = []
}
