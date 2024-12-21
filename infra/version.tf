terraform {
  required_version = ">= 1.8.6"
  backend "s3" {
    bucket                      = "seeker-opentofu-state"
    key                         = "terraform.tfstate"
    region                      = "WEUR"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://d4e789904d6943d8cd524e19c5cb36bd.r2.cloudflarestorage.com"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.4"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.13"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.13"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  owner = one(slice(split("/", var.repository), 0, 1))
}
