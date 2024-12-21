locals {
  dataset_id = replace(var.name, "-", "_")
}

module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 9.0"

  dataset_id   = local.dataset_id
  dataset_name = var.display_name
  description  = var.description
  project_id   = var.project
  location     = var.location
}

module "bigquery_assertions" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 9.0"

  dataset_id   = "${local.dataset_id}_assertions"
  dataset_name = "${var.display_name} assertions"
  description  = "Dataform assertions"
  project_id   = var.project
  location     = var.location
}

module "bigquery_datasets_iam" {
  source  = "terraform-google-modules/iam/google//modules/bigquery_datasets_iam"
  version = "~> 8.0"

  project            = var.project
  bigquery_datasets  = [module.bigquery.dataset_id, module.bigquery_assertions.dataset_id]
  mode               = "additive"

  bindings = {
    "roles/bigquery.dataEditor" = module.service_accounts.emails_list
  }
}

resource "google_bigquery_data_transfer_config" "binance_transactions" {
  project                = var.project
  location               = var.location
  data_source_id         = "google_cloud_storage"
  display_name           = "${var.display_name} Binance Transactions"
  schedule               = "first sunday of quarter 00:00"
  destination_dataset_id = local.dataset_id
  params = {
    destination_table_name_template = "binance_transactions"
    data_path_template              = "${module.cloud_storage.url}/*.csv"
    write_disposition               = "APPEND"
    file_format                 = "CSV"
    skip_leading_rows = 1
  }
  service_account_name = module.service_accounts.email
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
      user_private_key_secret_version = local.github_deploy_key_secret_version
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