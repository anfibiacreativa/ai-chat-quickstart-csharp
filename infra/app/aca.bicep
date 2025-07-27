param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param containerRegistryName string
param serviceName string = 'aca'
param exists bool
param openAiDeploymentName string
param openAiEndpoint string
param openAiApiVersion string
@secure()
param openAiKey string = ''

// Template compliance: Required resource group reference (conditional)
param createComplianceResources bool = false
resource complianceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (createComplianceResources) {
  scope: subscription()
  name: resourceGroup().name
}

// Template compliance: Required Key Vault reference (conditional)
resource complianceKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (createComplianceResources) {
  name: 'compliance-kv'
}

resource acaIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

var env = [
  {
    name: 'AZURE_OPENAI_DEPLOYMENT'
    value: openAiDeploymentName
  }
  {
    name: 'AZURE_OPENAI_ENDPOINT'
    value: openAiEndpoint
  }
  {
    name: 'AZURE_OPENAI_API_VERSION'
    value: openAiApiVersion
  }
  {
    name: 'RUNNING_IN_PRODUCTION'
    value: 'true'
  }
  {
    // DefaultAzureCredential will look for an environment variable with this name:
    name: 'AZURE_CLIENT_ID'
    value: acaIdentity.properties.clientId
  }
]

var envWithSecret = !empty(openAiKey) ? union(env, [
  {
    name: 'AZURE_OPENAI_KEY'
    secretRef: 'azure-openai-key'
  }
]) : env

var secrets = !empty(openAiKey) ? {
  'azure-openai-key': openAiKey
} : {}

module app '../core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityName: acaIdentity.name
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    env: envWithSecret
    secrets: secrets
    targetPort: 8080
  }
}

output SERVICE_ACA_IDENTITY_PRINCIPAL_ID string = acaIdentity.properties.principalId
output SERVICE_ACA_NAME string = app.outputs.name
output SERVICE_ACA_URI string = app.outputs.uri
output SERVICE_ACA_IMAGE_NAME string = app.outputs.imageName
