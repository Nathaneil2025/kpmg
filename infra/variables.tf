variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "71d6ab4d-a2ae-4612-b630-7bda563937fe"
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

