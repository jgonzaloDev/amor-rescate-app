# Azure info
variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# Key Vault
variable "key_vault_name" {
  type = string
}

# IAM principal (Federated Credential Object ID)
variable "github_principal_id" {
  type        = string
  description = "Object ID del GitHub Federated Credential"
}

# Secrets
variable "secret_bd_datos" {
  type = string
}

variable "secret_userbd" {
  type = string
}

variable "secret_passwordbd" {
  type = string
}
