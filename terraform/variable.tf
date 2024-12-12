variable "name" {
  type        = string
  default     = "data"
  description = "Name"
}

variable "display_name" {
  type        = string
  default     = "Data Platform"
  description = "Human readable name"
}

variable "description" {
  type        = string
  default     = "Data Platform"
  description = "Description"
}

variable "project" {
  type        = string
  description = "Google Project ID"
  default     = "shikanime-studio-labs"
}

variable "region" {
  type        = string
  description = "Google Cloud region"
  default     = "europe-west3"
}

variable "location" {
  type        = string
  description = "Google Cloud region or multi-region"
  default     = "EU"
}

variable "repository" {
  type        = string
  description = "Name of the repository"
  default     = "infinity-blackhole/data-platform-poc"
}
