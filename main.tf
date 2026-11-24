locals {
  domain = "cocahome.click"

  # Order matters: cloudflared matches ingress rules top to bottom
  services = [
    { subdomain = "media", service = "http://127.0.0.1:3080" },
    { subdomain = "portfolio", service = "http://127.0.0.1:1995" },
    { subdomain = "webdav", service = "http://127.0.0.1:8000" },
    { subdomain = "app", service = "http://3.26.219.247" },
    { subdomain = "connect", service = "http://127.0.0.1:8088" },
    { subdomain = "eve", service = "http://192.168.29.173:80" },
    { subdomain = "cdn", service = "http://127.0.0.1:8090" },
    { subdomain = "cms", service = "http://127.0.0.1:8090" },
  ]
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "home" {
  account_id = var.account_id
  name       = "cocahome"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "home" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.home.id

  config = {
    ingress = concat(
      [for s in local.services : {
        hostname = "${s.subdomain}.${local.domain}"
        service  = s.service
      }],
      [{ service = "http_status:404" }]
    )
  }
}

resource "cloudflare_dns_record" "tunnel" {
  for_each = { for s in local.services : s.subdomain => s }

  # Never publish eve before its Access app exists (EVE has default admin credentials)
  depends_on = [cloudflare_zero_trust_access_application.eve]

  zone_id = var.zone_id
  name    = "${each.key}.${local.domain}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.home.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

#resource "cloudflare_dns_record" "app" {
#  zone_id = var.zone_id
#  name    = "app.${local.domain}"
#  type    = "A"
#  content = "3.26.219.247"
#  proxied = true
#  ttl     = 1
#}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

# EVE-NG web UI: only listed emails may pass Cloudflare Access (repo variable ACCESS_EMAILS, JSON list)
resource "cloudflare_zero_trust_access_policy" "eve_owner" {
  account_id = var.account_id
  name       = "eve-owner-only"
  decision   = "allow"
  include    = [for e in var.access_emails : { email = { email = e } }]
}

resource "cloudflare_zero_trust_access_application" "eve" {
  account_id       = var.account_id
  name             = "eve"
  type             = "self_hosted"
  domain           = "eve.${local.domain}"
  session_duration = "24h"
  policies = [{
    id         = cloudflare_zero_trust_access_policy.eve_owner.id
    precedence = 1
  }]
}
