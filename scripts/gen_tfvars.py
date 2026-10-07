#!/usr/bin/env python3
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Generate terraform.tfvars")
    parser.add_argument("domain", help="Domain on Cloudflare")
    parser.add_argument("--force", action="store_true", help="Overwrite existing file")
    args = parser.parse_args()
    token = os.getenv("CLOUDFLARE_API_TOKEN")
    if not token:
        print("CLOUDFLARE_API_TOKEN is not set", file=sys.stderr)
        sys.exit(1)
    path = Path(__file__).resolve().parent.parent / "terraform.tfvars"
    if path.exists() and not args.force:
        print(f"{path} already exists, use --force to overwrite", file=sys.stderr)
        sys.exit(1)
    query = urllib.parse.urlencode({"name": args.domain})
    url = f"https://api.cloudflare.com/client/v4/zones?{query}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        print(f"Cloudflare API error: HTTP {e.code} {e.reason}", file=sys.stderr)
        sys.exit(1)
    if not data["success"]:
        print(f"Cloudflare API error: {data['errors']}", file=sys.stderr)
        sys.exit(1)
    if not data["result"]:
        print(f"Zone not found: {args.domain}", file=sys.stderr)
        sys.exit(1)
    zone = data["result"][0]
    zone_id = zone["id"]
    account_id = zone["account"]["id"]
    content = f'zone_id    = "{zone_id}"\naccount_id = "{account_id}"\n'
    path.write_text(content)
    path.chmod(0o600)
    print(f"wrote {path}")


if __name__ == "__main__":
    main()
