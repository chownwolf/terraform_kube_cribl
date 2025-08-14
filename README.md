1️⃣ Prerequisites
Item	How to get it
Terraform v1.7+	brew install terraform (macOS) or download from 

Google Cloud SDK	gcloud init, set default project & zone, enable billing
A GCP account with permissions	Owner/Editor role on the target project, or at least IAM roles for roles/container.admin, roles/resourcemanager.projectCreator, etc.
Docker Hub credentials (optional)	If you want to pull Cribl from Docker Hub, set CRIBL_DOCKERHUB_USERNAME & CRIBL_DOCKERHUB_TOKEN. The public image cribl/stream:latest is available without auth.

2️⃣ Directory Layout
terraform-cribl/
├── main.tf
├── variables.tf
├── outputs.tf
└── provider.tf
