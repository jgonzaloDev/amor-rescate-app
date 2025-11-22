terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

###############################################################
# 1️⃣ Resource Group
###############################################################
resource "azurerm_resource_group" "dojo" {
  name     = var.resource_group_name
  location = var.location
}

###############################################################
# 2️⃣ Key Vault con RBAC
###############################################################
resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  resource_group_name         = azurerm_resource_group.dojo.name
  location                    = azurerm_resource_group.dojo.location
  tenant_id                   = var.tenant_id

  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true
}

###############################################################
# 3️⃣ GitHub OIDC → Key Vault Secrets Officer
###############################################################
resource "azurerm_role_assignment" "github_kv_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.github_principal_id
}

###############################################################
# 4️⃣ 🔐 TU USUARIO → Key Vault Administrator
###############################################################
resource "azurerm_role_assignment" "user_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = "d367b5ee-a181-4d51-824a-70861fd4a79c" # TU USER OBJECT ID
}

###############################################################
# 5️⃣ Propagación RBAC (Azure se demora)
###############################################################
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    azurerm_role_assignment.github_kv_secrets,
    azurerm_role_assignment.user_kv_admin
  ]
  create_duration = "45s"
}
###############################################################
# 6️⃣ Secretos del Key Vault — OPCIÓN A (NO falla si ya existen)
###############################################################

########################
# BDdatos
########################
locals {
  bd_datos_existing = try(data.azurerm_key_vault_secret.bd_datos_existing.value, "")
}

data "azurerm_key_vault_secret" "bd_datos_existing" {
  name         = "BDdatos"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "bd_datos" {
  count = local.bd_datos_existing == "" ? 1 : 0

  name         = "BDdatos"
  value        = var.secret_bd_datos
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_iam]
}

########################
# userbd
########################
locals {
  userbd_existing = try(data.azurerm_key_vault_secret.userbd_existing.value, "")
}

data "azurerm_key_vault_secret" "userbd_existing" {
  name         = "userbd"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "userbd" {
  count = local.userbd_existing == "" ? 1 : 0

  name         = "userbd"
  value        = var.secret_userbd
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_iam]
}

########################
# passwordbd
########################
locals {
  passwordbd_existing = try(data.azurerm_key_vault_secret.passwordbd_existing.value, "")
}

data "azurerm_key_vault_secret" "passwordbd_existing" {
  name         = "passwordbd"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "passwordbd" {
  count = local.passwordbd_existing == "" ? 1 : 0

  name         = "passwordbd"
  value        = var.secret_passwordbd
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_iam]
}
