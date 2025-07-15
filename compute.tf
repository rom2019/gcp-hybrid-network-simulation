# compute.tf - VM 인스턴스 및 서비스 계정

# Dev VM Service Account
resource "google_service_account" "dev_vm_sa" {
  account_id   = "dev-vm-sa"
  display_name = "Dev VM Service Account"
  project      = google_project.dev_project.project_id
}

# Dev VM에 필요한 IAM 역할
resource "google_project_iam_member" "dev_vm_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/aiplatform.user",  # Gemini API 사용을 위해
  ])
  
  project = google_project.dev_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.dev_vm_sa.email}"
}

# Prod 프로젝트에서 Gemini API 사용 권한
resource "google_project_iam_member" "dev_vm_prod_access" {
  project = google_project.prod_project.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.dev_vm_sa.email}"
}

# Dev Workstation VM
resource "google_compute_instance" "dev_workstation" {
  name         = "dev-workstation"
  machine_type = var.dev_vm_machine_type
  zone         = var.zone
  project      = google_project.dev_project.project_id
  
  tags = ["dev-vm", "ssh-allowed", "vpn-allowed"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
      type  = "pd-standard"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.dev_subnet.id
    
    # 외부 IP 할당 (SSH 접속용)
    access_config {
      // Ephemeral public IP
    }
  }
  
  service_account {
    email  = google_service_account.dev_vm_sa.email
    scopes = ["cloud-platform"]
  }
  
  metadata = {
    enable-oslogin = "TRUE"
  }
  
  metadata_startup_script = <<-EOT
    #!/bin/bash
    # 기본 개발 도구 설치
    apt-get update
    apt-get install -y git curl wget python3-pip
    
    # Google Cloud SDK 설치
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    apt-get install -y apt-transport-https ca-certificates gnupg
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update && apt-get install -y google-cloud-sdk
    
    # VS Code Server 설치 (선택사항)
    # curl -fsSL https://code-server.dev/install.sh | sh
    
    # 네트워크 테스트 도구
    apt-get install -y iputils-ping traceroute netcat dnsutils
    
    # Python 클라이언트 라이브러리 설치
    pip3 install google-cloud-aiplatform
    
    # 테스트 스크립트 생성
    cat > /home/debian/test_gemini.py << 'EOF'
#!/usr/bin/env python3
import vertexai
from vertexai.generative_models import GenerativeModel

# Prod 프로젝트 ID로 초기화
PROJECT_ID = "${google_project.prod_project.project_id}"
LOCATION = "us-central1"

vertexai.init(project=PROJECT_ID, location=LOCATION)

model = GenerativeModel("gemini-pro")
response = model.generate_content("Hello, Gemini! This is a test from the simulated on-premises environment.")
print(response.text)
EOF
    
    chmod +x /home/debian/test_gemini.py
    chown debian:debian /home/debian/test_gemini.py
    
    echo "Dev workstation setup complete!"
  EOT
  
  depends_on = [
    google_compute_subnetwork.dev_subnet,
    google_service_account.dev_vm_sa,
  ]
}

# Prod 환경의 테스트용 VM (선택사항)
resource "google_compute_instance" "prod_test_vm" {
  count        = 0  # 기본적으로 생성하지 않음
  name         = "prod-test-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  project      = google_project.prod_project.project_id
  
  tags = ["prod-vm", "internal-only"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
      type  = "pd-standard"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.prod_subnet.id
    # 외부 IP 없음 (내부 전용)
  }
  
  service_account {
    scopes = ["cloud-platform"]
  }
  
  metadata = {
    enable-oslogin = "TRUE"
  }
}