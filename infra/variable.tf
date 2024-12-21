variable "name" {
  type        = string
  default     = "seeker"
  description = "Name"
}

variable "display_name" {
  type        = string
  default     = "Shikanime Data Platform"
  description = "Human readable name"
}

variable "description" {
  type        = string
  default     = "Shikanime Data Platform"
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
  default     = "europe-west9"
}

variable "location" {
  type        = string
  description = "Google Cloud region or multi-region"
  default     = "europe-west9"
}

variable "repository" {
  type        = string
  description = "Name of the repository"
  default     = "shikanime/seeker"
}
