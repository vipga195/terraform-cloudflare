variable "zone_id" {
  type        = string
  description = "Zone ID của domain trên Cloudflare"
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID"
}

variable "access_email" {
  type        = string
  description = "Email allowed through Cloudflare Access (set via TF_VAR_access_email)"
  sensitive   = true
}
