terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.107"
    }
  }

  backend "azurerm" {
    resource_group_name  = "platform_candidate_2" # backend must stay static
    storage_account_name = "tfkpm2025"            # backend must stay static
    container_name       = "tfstate"
    key                  = "infra/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
