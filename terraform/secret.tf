resource "tls_private_key" "github_deploy_key" {
  algorithm = "ED25519"
}

module "secret_manager" {
  source  = "GoogleCloudPlatform/secret-manager/google"
  version = "~> 0.5"

  project_id = var.project
  secrets = [
    {
      name        = "${var.name}-github-deploy-key"
      secret_data = tls_private_key.github_deploy_key.private_key_openssh
    },
  ]
}

module "secret_manager_iam" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "~> 8.0"

  project = data.google_project.default.number
  secrets = module.secret_manager.secret_names
  mode    = "additive"

  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:service-${data.google_project.default.number}@gcp-sa-dataform.iam.gserviceaccount.com"
    ]
  }
}

data "github_repository" "default" {
  full_name = var.repository
}

resource "github_repository_deploy_key" "dataform" {
  title      = "${var.display_name} Dataform"
  repository = data.github_repository.default.id
  key        = tls_private_key.github_deploy_key.public_key_openssh
  read_only  = false
}
