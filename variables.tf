# variables.tf
variable "project_id" {
  description = "GCP Project ID (will be created if not exist)"
  type        = string
}

variable "region" {
  description = "Region for resources"
  default     = "us-central1"
  type        = string
}

variable "zone" {
  description = "Zone for GKE cluster nodes"
  default     = "us-central1-a"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  default     = "cribl-gke"
  type        = string
}

variable "node_count" {
  description = "Initial number of nodes per pool"
  default     = 3
  type        = number
}

variable "min_node_count" {
  description = "Min nodes for autoscaler"
  default     = 1
  type        = number
}

variable "max_node_count" {
  description = "Max nodes for autoscaler"
  default     = 6
  type        = number
}

variable "cribl_image_tag" {
  description = "Cribl Stream Docker image tag"
  default     = "latest"
  type        = string
}
