# cloudrun.tf
resource "google_cloud_run_v2_service" "cribl" {
  name     = "cribl"
  location = var.region

  template {
    containers {
      image = "cribl/stream:${var.cribl_image_tag}"
      ports {
        container_port = 9000
      }
    }

    scaling {
      min_instance_count = 1
      max_instance_count = 3
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

output "cloud_run_url" {
  value = google_cloud_run_v2_service.cribl.uri
}
