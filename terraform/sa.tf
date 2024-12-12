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

module "service_accounts_iam" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "~> 8.0"

  project          = var.project
  mode             = "additive"
  service_accounts = module.service_accounts.emails_list
  bindings = {
    "roles/iam.serviceAccountTokenCreator" = [
      "serviceAccount:service-${data.google_project.default.number}@gcp-sa-dataform.iam.gserviceaccount.com"
    ]
  }
}
