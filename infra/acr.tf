# Reference the existing ACR "acrcandidates" in resource group "ai-candidates"
data "azurerm_container_registry" "chatbot_acr" {
  name                = "myacrtask"
  resource_group_name = "platform_candidate_2"
  #comment
}

