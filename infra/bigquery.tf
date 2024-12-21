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

  access = [
    {
      role          = "OWNER"
      special_group = "projectOwners"
    },
    {
      role          = "READER"
      user_by_email = "service-${data.google_project.default.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
    },
    {
      role          = "WRITER"
      user_by_email = module.service_accounts.email
    }
  ]
  tables = [
    {
      table_id    = "binance_transactions"
      description = "Binance transactions"
      table_name  = "Binance Transactions"
      schema = jsonencode([
        {
          name        = "User_ID"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Unique identifier for the user"
        },
        {
          name        = "UTC_Time"
          type        = "TIMESTAMP"
          mode        = "REQUIRED"
          description = "Timestamp of the transaction in UTC"
        },
        {
          name        = "Account"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Account identifier where the transaction occurred"
        },
        {
          name        = "Operation"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Type of operation performed"
        },
        {
          name        = "Coin"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Cryptocurrency symbol"
        },
        {
          name        = "Change"
          type        = "FLOAT64"
          mode        = "REQUIRED"
          description = "Amount of cryptocurrency involved in the transaction"
        },
        {
          name        = "Remark"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Additional notes or comments about the transaction"
        }
      ])
      clustering = [
        "User_ID",
        "Account",
      ]
      require_partition_filter = true
      time_partitioning = {
        expiration_ms = null
        field         = "UTC_Time"
        type          = "DAY"
      }
      range_partitioning = null
      expiration_time    = null
      labels             = {}
    },
    {
      table_id    = "sg_current_transactions"
      description = "Societe Generale current account transactions"
      table_name  = "SG Current"
      schema = jsonencode([
        {
          name        = "date_de_l_operation"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Original date string of the operation"
        },
        {
          name        = "libelle"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Transaction label or description"
        },
        {
          name        = "detail_de_l_ecriture"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Detailed description of the transaction"
        },
        {
          name        = "montant_de_l_operation"
          type        = "FLOAT64"
          mode        = "REQUIRED"
          description = "Transaction amount"
        },
        {
          name        = "devise"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Currency code"
        }
      ])
      clustering               = []
      require_partition_filter = false
      time_partitioning        = null
      range_partitioning       = null
      expiration_time          = null
      labels                   = {}
    },
    {
      table_id    = "sg_saving_transactions"
      description = "Societe Generale savings transactions"
      table_name  = "SG Saving"
      schema = jsonencode([
        {
          name        = "date_comptabilisation"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Original accounting date string"
        },
        {
          name        = "libelle_complet_operation"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Complete transaction description"
        },
        {
          name        = "montant_operation"
          type        = "FLOAT64"
          mode        = "REQUIRED"
          description = "Transaction amount"
        },
        {
          name        = "devise"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Currency code"
        }
      ])
      clustering               = []
      require_partition_filter = false
      time_partitioning        = null
      range_partitioning       = null
      expiration_time          = null
      labels                   = {}
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
  access = [
    {
      role          = "OWNER"
      special_group = "projectOwners"
    },
    {
      role          = "WRITER"
      user_by_email = module.service_accounts.email
    }
  ]
}

resource "google_bigquery_data_transfer_config" "binance_transactions" {
  project                = var.project
  location               = var.location
  data_source_id         = "google_cloud_storage"
  display_name           = "${var.display_name} Binance Transactions"
  schedule               = "first sunday of quarter 00:00"
  destination_dataset_id = local.dataset_id
  params = {
    destination_table_name_template = module.bigquery.table_ids[0]
    data_path_template              = "${module.cloud_storage.urls["binance-exports"]}/*.csv"
    write_disposition               = "APPEND"
    file_format                     = "CSV"
    skip_leading_rows               = 1
  }
  service_account_name = module.service_accounts.email
}

resource "google_bigquery_data_transfer_config" "sg_current" {
  project                = var.project
  location               = var.location
  data_source_id         = "google_cloud_storage"
  display_name           = "${var.display_name} SG Current Account"
  schedule               = "first sunday of quarter 00:00"
  destination_dataset_id = local.dataset_id
  params = {
    destination_table_name_template = module.bigquery.table_ids[1]
    data_path_template              = "${module.cloud_storage.urls["sg-exports"]}/current/*.csv"
    write_disposition               = "APPEND"
    file_format                     = "CSV"
    skip_leading_rows               = 3
    field_delimiter                 = ";"
  }
  service_account_name = module.service_accounts.email
}

resource "google_bigquery_data_transfer_config" "sg_saving" {
  project                = var.project
  location               = var.location
  data_source_id         = "google_cloud_storage"
  display_name           = "${var.display_name} SG Saving Accounts"
  schedule               = "first sunday of quarter 00:00"
  destination_dataset_id = local.dataset_id
  params = {
    destination_table_name_template = module.bigquery.table_ids[2]
    data_path_template              = "${module.cloud_storage.urls["sg-exports"]}/saving/*.csv"
    write_disposition               = "APPEND"
    file_format                     = "CSV"
    skip_leading_rows               = 2
    field_delimiter                 = ";"
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