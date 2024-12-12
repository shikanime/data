terraform {
  required_version = ">= 1.8.6"
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
