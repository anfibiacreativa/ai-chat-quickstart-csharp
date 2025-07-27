metadata description = 'Creates a Log Analytics workspace.'
param name string
param location string = resourceGroup().location
param tags object = {}

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

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

output id string = logAnalytics.id
output name string = logAnalytics.name
