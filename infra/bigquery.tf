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

  external_tables = [
    {
      table_id              = "binance_transactions_source",
      description           = "Binance transactions source",
      autodetect            = false,
      compression           = null,
      ignore_unknown_values = false,
      max_bad_records       = null,
      expiration_time       = null,
      google_sheets_options = null,
      source_format         = "CSV",
      source_uris = [
        "${module.cloud_storage.urls["binance-exports"]}/*.csv"
      ],
      csv_options = {
        skip_leading_rows     = 1,
        allow_quoted_newlines = false,
        allow_jagged_rows     = false,
        encoding              = "UTF-8",
        field_delimiter       = ",",
        quote                 = "\"",
      },
      hive_partitioning_options = {
        mode              = "AUTO"
        source_uri_prefix = "${module.cloud_storage.urls["binance-exports"]}/"
      }
      schema = jsonencode([
        {
          name : "User_ID",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "UTC_Time",
          type : "TIMESTAMP",
          mode : "REQUIRED"
        },
        {
          name : "Account",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "Operation",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "Coin",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "Change",
          type : "FLOAT64",
          mode : "REQUIRED"
        },
        {
          name : "Remark",
          type : "STRING",
          mode : "REQUIRED"
        }
      ]),
      labels = {}
    },
    {
      table_id              = "sg_current_transactions_source",
      description           = null,
      autodetect            = false,
      compression           = null,
      ignore_unknown_values = false,
      max_bad_records       = null,
      expiration_time       = null,
      google_sheets_options = null,
      source_format         = "CSV",
      source_uris           = ["${module.cloud_storage.urls["sg-exports"]}/current/*.csv"],
      csv_options = {
        quote                 = ""
        skip_leading_rows     = 3
        field_delimiter       = ";"
        allow_quoted_newlines = false
        allow_jagged_rows     = false
        encoding              = "UTF-8"
      },
      hive_partitioning_options = {
        mode              = "AUTO"
        source_uri_prefix = "${module.cloud_storage.urls["sg-exports"]}/current/"
      },
      schema = jsonencode([
        {
          name : "date_de_l_operation",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "libelle",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "detail_de_l_ecriture",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "montant_de_l_operation",
          type : "FLOAT64",
          mode : "REQUIRED"
        },
        {
          name : "devise",
          type : "STRING",
          mode : "REQUIRED"
        }
      ]),
      labels = {}
    },
    {
      table_id              = "sg_saving_transactions_source",
      description           = null,
      autodetect            = false,
      compression           = null,
      ignore_unknown_values = false,
      max_bad_records       = null,
      expiration_time       = null,
      google_sheets_options = null,
      source_format         = "CSV",
      source_uris           = ["${module.cloud_storage.urls["sg-exports"]}/saving/*.csv"],
      csv_options = {
        quote                 = ""
        skip_leading_rows     = 2
        field_delimiter       = ";"
        allow_quoted_newlines = false
        allow_jagged_rows     = false
        encoding              = "UTF-8"
      },
      hive_partitioning_options = {
        mode              = "AUTO"
        source_uri_prefix = "${module.cloud_storage.urls["sg-exports"]}/saving/"
      },
      schema = jsonencode([
        {
          name : "date_comptabilisation",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "libelle_complet_operation",
          type : "STRING",
          mode : "REQUIRED"
        },
        {
          name : "montant_operation",
          type : "FLOAT64",
          mode : "REQUIRED"
        },
        {
          name : "devise",
          type : "STRING",
          mode : "REQUIRED"
        }
      ]),
      labels = {}
    }
  ]
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