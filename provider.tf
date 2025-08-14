# provider.tf
terraform {
  required_version = ">= 1.7"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
