terraform {
  backend "s3" {
    bucket = "terraform"
    key    = "cloudflare/prod.tfstate"
    region = "auto"
    endpoints = {
      s3 = "https://ca566497a6fc07f69ed279c3e40ce8eb.r2.cloudflarestorage.com"
    }
    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    encrypt                     = true
  }
}