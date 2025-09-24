data "azurerm_container_registry" "chatbot_acr" {
  name                = "acrcandidates"
  resource_group_name = var.resource_group_name
}
