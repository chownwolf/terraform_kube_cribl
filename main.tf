# main.tf

#########################
## 1️⃣ Project & APIs ##
#########################

resource "google_project" "this" {
  project_id   = var.project_id
  name         = "Cribl Kubernetes Project"
  billing_account = var.billing_account # optional if you already enabled billing
}

resource "google_project_service" "gke_api" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "storage-component.googleapis.com"
  ])

  project                    = google_project.this.project_id
  service                    = each.key
  disable_on_destroy         = false
  enable_dependent_services = true
}

#############################
## 2️⃣ GKE Cluster & NodePool ##
#############################

resource "google_container_cluster" "cribl" {
  name     = var.cluster_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1   # placeholder; actual nodes in pool

  network    = google_compute_network.cribl.name
  subnetwork = google_compute_subnetwork.cribl.name

  enable_autopilot = false

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = ["k8s-node"]
  }

  # Enable GKE IAM Auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  lifecycle {
    ignore_changes = [node_pool]   # we manage node pools separately
  }
}

resource "google_container_node_pool" "default" {
  name       = "${var.cluster_name}-np"
  location   = var.zone
  cluster    = google_container_cluster.cribl.name

  initial_node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    machine_type = "e2-medium"

    preemptible = false

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "cribl"
    }

    tags = ["k8s-node"]
  }
}

#########################
## 3️⃣ Networking ##
#########################

resource "google_compute_network" "cribl" {
  name                    = "${var.cluster_name}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "cribl" {
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.cribl.id
  ip_cidr_range = "10.0.0.0/20"

  secondary_ip_ranges = [
    {
      range_name    = "pods"
      ip_cidr_range = "10.8.0.0/14"
    },
    {
      range_name    = "services"
      ip_cidr_range = "10.12.0.0/16"
    }
  ]
}

#########################
## 4️⃣ Helm Provider ##
#########################

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Grab credentials from the GKE cluster
data "google_container_cluster" "cluster" {
  name     = google_container_cluster.cribl.name
  location = var.zone
}

resource "null_resource" "kubectl_config" {
  provisioner "local-exec" {
    command = <<EOT
gcloud container clusters get-credentials ${google_container_cluster.cribl.name} --zone=${var.zone}
EOT
  }
  triggers = { cluster_id = google_container_cluster.cribl.id }
}

#########################
## 5️⃣ Install Cribl ##
#########################

resource "helm_release" "cribl" {
  name       = "cribl"
  namespace  = "cribl"
  repository = "https://charts.cribl.io/stable"
  chart      = "cribl-stream"

  # The official chart uses `image.repository` and `image.tag`
  values = [
    <<EOF
image:
  repository: cribl/stream
  tag: ${var.cribl_image_tag}
service:
  type: LoadBalancer
ingress:
  enabled: false
resources:
  limits:
    cpu: "2"
    memory: 4Gi
  requests:
    cpu: "1"
    memory: 2Gi
EOF
  ]

  depends_on = [null_resource.kubectl_config]
}

#########################
## 6️⃣ Outputs ##
#########################

output "kubeconfig" {
  description = "Kubeconfig content for the cluster"
  value       = data.google_container_cluster.cluster.master_auth.0.client_certificate
  sensitive   = true
}

output "cribl_service_ip" {
  description = "External IP of the Cribl service"
  value       = helm_release.cribl.status[0].load_balancer_ingress[0].ip
}
