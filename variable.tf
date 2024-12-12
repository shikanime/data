variable "name" {
  type        = string
  default     = "dataform"
  description = "Name"
}

variable "display_name" {
  type        = string
  default     = "Dataform"
  description = "Human readable name"
}

variable "description" {
  type        = string
  default     = "Dataform"
  description = "Description"
}

variable "project" {
  type        = string
  description = "Google Project ID"
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
