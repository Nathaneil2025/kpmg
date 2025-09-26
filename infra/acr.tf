# Reference existing ACR "myacrtask" in resource group "platform_candidate_2"
data "azurerm_container_registry" "chatbot_acr" {
  name                = "myacrtask"
  resource_group_name = "platform_candidate_2"
}
