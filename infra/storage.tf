module "storage" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 9.0"

  project_id  = var.project
  location    = var.location
  prefix = "${var.name}-${lower(var.location)}"
  names = [
    "societe-generale-datalake",
  ]
  versioning = {
    "societe-generale-datalake" = true
  }
  viewers =module.service_accounts.emails_list
}
