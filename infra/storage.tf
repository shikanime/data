module "cloud_storage" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 9.0"

  project_id = var.project
  location   = var.location
  prefix     = "${var.project}-${var.name}-${lower(var.location)}"
  names = [
    "sg-exports",
    "binance-exports",
  ]
  versioning = {
    "sg-exports"      = true
    "binance-exports" = true
  }
  set_viewer_roles = true
  viewers          = module.service_accounts.iam_emails_list
}
