resource "google_bigquery_dataset" "default" {
  project     = var.project
  dataset_id  = var.name
  location    = var.location
  description = "Dataset for ${var.name}"
}

resource "google_bigquery_dataset" "assertions" {
  project     = var.project
  dataset_id  = "${var.name}_assertions"
  location    = var.location
  description = "Dataset for ${var.name} Dataform assertions"
}

resource "google_dataform_repository" "default" {
  provider = google-beta

  project = var.project
  name    = var.name
  region  = var.region

  workspace_compilation_overrides {
    default_database = google_bigquery_dataset.default.project
  }
}

resource "google_dataform_repository_release_config" "default" {
  provider = google-beta

  project    = google_dataform_repository.default.project
  region     = google_dataform_repository.default.region
  repository = google_dataform_repository.default.name

  name          = var.name
  git_commitish = "main"
  cron_schedule = "0 7 * * *"
  time_zone     = "Europe/Paris"

  code_compilation_config {
    default_database = google_bigquery_dataset.default.project
    default_schema   = google_bigquery_dataset.default.dataset_id
    default_location = var.location
    assertion_schema = google_bigquery_dataset.assertions.dataset_id
  }
}

resource "google_service_account" "default" {
  provider = google-beta

  project      = var.project
  account_id   = "${var.name}-service-account"
  display_name = "${var.display_name} Service Account"
}

module "service_accounts" {
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 4.0"
  project_id    = var.project
  prefix        = var.name
  names         = ["release"]
  project_roles = [
    "${var.project}=>roles/bigquery.jobUser"
  ]
}

resource "google_dataform_repository_workflow_config" "default" {
  provider = google-beta

  project        = google_dataform_repository.default.project
  region         = google_dataform_repository.default.region
  repository     = google_dataform_repository.default.name
  name           = var.name
  release_config = google_dataform_repository_release_config.default.id

  invocation_config {
    transitive_dependencies_included         = true
    transitive_dependents_included           = true
    fully_refresh_incremental_tables_enabled = false
    service_account                          = module.service_accounts.email
  }

  cron_schedule = "0 7 * * *"
  time_zone     = "Europe/Paris"
}