variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "Resource group for all resources"
  type        = string
  default     = "platform_candidate_2"
}
