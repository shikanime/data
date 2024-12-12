module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 9.0"

  dataset_id   = var.name
  dataset_name = var.display_name
  description  = var.description
  project_id   = var.project
  location     = var.location
}

module "bigquery_assertions" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 9.0"

  dataset_id   = "${replace(var.name, "-", "_")}_assertions"
  dataset_name = "${var.display_name} assertions"
  description  = "Dataform assertions"
  project_id   = var.project
  location     = var.location
}

resource "google_dataform_repository" "default" {
  provider = google-beta

  project = var.project
  name    = var.name
  region  = var.region

  service_account = module.service_accounts.email

  workspace_compilation_overrides {
    default_database = var.project
  }
  git_remote_settings {
    url            = "ssh://git@github.com/${var.repository}"
    default_branch = "main"
    ssh_authentication_config {
      user_private_key_secret_version = module.secret_manager.secret_versions[0]
      host_public_key = join("\n", [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
      ])
    }
  }
}

resource "google_dataform_repository_release_config" "main" {
  provider = google-beta

  project    = google_dataform_repository.default.project
  region     = google_dataform_repository.default.region
  repository = google_dataform_repository.default.name

  name          = "main"
  git_commitish = "main"
  time_zone     = "Europe/Paris"

  code_compilation_config {
    default_database = var.project
    default_schema   = var.name
    default_location = var.location
    assertion_schema = "${var.name}-assertions"
  }
}

resource "google_dataform_repository_workflow_config" "daily" {
  provider = google-beta

  project        = google_dataform_repository.default.project
  region         = google_dataform_repository.default.region
  repository     = google_dataform_repository.default.name
  name           = "daily"
  release_config = google_dataform_repository_release_config.main.id

  invocation_config {
    transitive_dependencies_included         = true
    transitive_dependents_included           = true
    fully_refresh_incremental_tables_enabled = false
    service_account                          = module.service_accounts.email
  }

  cron_schedule = "0 4 * * *"
  time_zone     = "Europe/Paris"
}