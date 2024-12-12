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
