# Reference the existing ACR "acrcandidates" in resource group "ai-candidates"
data "azurerm_container_registry" "chatbot_acr" {
  name                = "acrcandidates"
  resource_group_name = "ai-candidates"
}
