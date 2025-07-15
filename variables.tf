# variables.tf - Terraform 변수 정의

variable "billing_account_id" {
  description = "GCP Billing Account ID"
  type        = string
}

variable "organization_id" {
  description = "GCP Organization ID (VPC Service Controls를 사용하는 경우 필요)"
  type        = string
  default     = ""
}

variable "region" {
  description = "기본 리전"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "기본 존"
  type        = string
  default     = "us-central1-a"
}

variable "dev_project_id" {
  description = "Dev (On-premises simulation) 프로젝트 ID"
  type        = string
  default     = "on-prem-sim"
}

variable "prod_project_id" {
  description = "Production (Gemini API) 프로젝트 ID"
  type        = string
  default     = "gemini-api-prod"
}

variable "dev_vpc_cidr" {
  description = "Dev VPC CIDR 범위"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dev_subnet_cidr" {
  description = "Dev Subnet CIDR 범위"
  type        = string
  default     = "10.0.1.0/24"
}

variable "prod_vpc_cidr" {
  description = "Prod VPC CIDR 범위"
  type        = string
  default     = "10.1.0.0/16"
}

variable "prod_subnet_cidr" {
  description = "Prod Subnet CIDR 범위"
  type        = string
  default     = "10.1.1.0/24"
}

variable "vpn_shared_secret" {
  description = "VPN 공유 비밀키"
  type        = string
  sensitive   = true
}

variable "dev_vm_machine_type" {
  description = "Dev VM 머신 타입"
  type        = string
  default     = "e2-medium"
}

variable "enable_vpc_service_controls" {
  description = "VPC Service Controls 활성화 여부"
  type        = bool
  default     = false
}

variable "allowed_ssh_source_ranges" {
  description = "SSH 접속을 허용할 소스 IP 범위"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "project_labels" {
  description = "프로젝트에 적용할 라벨"
  type        = map(string)
  default = {
    environment = "simulation"
    purpose     = "gemini-api-test"
  }
}