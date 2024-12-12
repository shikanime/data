module "service_accounts" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  project_id   = var.project
  prefix       = var.name
  names        = ["workflow"]
  display_name = "${var.display_name} Workflow Service Account"
  project_roles = [
    "${var.project}=>roles/bigquery.jobUser",
    "${var.project}=>roles/bigquery.dataEditor"
  ]
}
