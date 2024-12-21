module "cloud_storage" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 9.0"

  project_id = var.project
  location   = var.location
  prefix     = "${var.project}-${var.name}-${lower(var.location)}"
  names = [
    "sg-exports",
  ]
  versioning = {
    "sg-datalake" = true
  }
  viewers = module.service_accounts.emails_list
}
