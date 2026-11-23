locals {
  domain = "cocahome.click"

  # Order matters: cloudflared matches ingress rules top to bottom
  services = [
    { subdomain = "media", service = "http://host.docker.internal:8080" },
    { subdomain = "portfolio", service = "http://host.docker.internal:1995" },
    { subdomain = "deploy", service = "http://deploy-hook:9000" },
    { subdomain = "webdav", service = "http://host.docker.internal:8000" },
    { subdomain = "app", service = "http://3.26.219.247" },
    { subdomain = "connect", service = "http://host.docker.internal:8088" },
    { subdomain = "eve", service = "http://192.168.29.173:80" },
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

# EVE-NG web UI: only the owner's email may pass Cloudflare Access
resource "cloudflare_zero_trust_access_policy" "eve_owner" {
  account_id = var.account_id
  name       = "eve-owner-only"
  decision   = "allow"
  include    = [{ email = { email = var.access_email } }]
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
