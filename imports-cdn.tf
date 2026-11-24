# Hand-made DNS records adopted during the CDN cutover (kept in git so CI applies the import)
import {
  to = cloudflare_dns_record.tunnel["cdn"]
  id = "${var.zone_id}/0cc27be755c5304849ca580131f0c9fe"
}

import {
  to = cloudflare_dns_record.tunnel["cms"]
  id = "${var.zone_id}/7da34d2091641ac5aeee75de5379f9e1"
}
