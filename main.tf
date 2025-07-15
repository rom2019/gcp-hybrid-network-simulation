# main.tf - Terraform 프로바이더 및 프로젝트 설정

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# 프로바이더 설정
provider "google" {
  region = var.region
}

provider "google-beta" {
  region = var.region
}

# 랜덤 프로젝트 ID 접미사 생성 (중복 방지)
resource "random_id" "project_suffix" {
  byte_length = 4
}

# Dev 프로젝트 (On-premises 시뮬레이션)
resource "google_project" "dev_project" {
  name            = "On-Premises Simulation"
  project_id      = "${var.dev_project_id}-${random_id.project_suffix.hex}"
  billing_account = var.billing_account_id
  labels          = var.project_labels
}

# Prod 프로젝트 (Gemini API)
resource "google_project" "prod_project" {
  name            = "Gemini API Production"
  project_id      = "${var.prod_project_id}-${random_id.project_suffix.hex}"
  billing_account = var.billing_account_id
  labels          = var.project_labels
}

# Dev 프로젝트 API 활성화
resource "google_project_service" "dev_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "vpn-gateway.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])
  
  project = google_project.dev_project.project_id
  service = each.key
  
  disable_on_destroy = false
}

# Prod 프로젝트 API 활성화
resource "google_project_service" "prod_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "vpn-gateway.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudaicompanion.googleapis.com",  # Gemini Code Assist
  ])
  
  project = google_project.prod_project.project_id
  service = each.key
  
  disable_on_destroy = false
}

# VPC Service Controls를 위한 API (선택사항)
resource "google_project_service" "vpc_sc_apis" {
  for_each = var.enable_vpc_service_controls ? toset([
    "accesscontextmanager.googleapis.com",
  ]) : toset([])
  
  project = google_project.prod_project.project_id
  service = each.key
  
  disable_on_destroy = false
}

# API 활성화 대기
resource "time_sleep" "wait_for_apis" {
  depends_on = [
    google_project_service.dev_apis,
    google_project_service.prod_apis,
    google_project_service.vpc_sc_apis,
  ]
  
  create_duration = "30s"
}