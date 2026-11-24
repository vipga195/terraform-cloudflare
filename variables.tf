variable "zone_id" {
  type        = string
  description = "Zone ID của domain trên Cloudflare"
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID"
}

variable "access_emails" {
  type        = list(string)
  description = "Emails allowed through Cloudflare Access (set via TF_VAR_access_emails, e.g. [\"a@x.com\"])"
  sensitive   = true
}
