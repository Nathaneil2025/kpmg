# Reference the existing ACR "acrcandidates" in resource group "ai-candidates"
data "azurerm_container_registry" "chatbot_acr" {
  name                = "myacr2025kpm"
  resource_group_name = "platform_candidate_2"
}