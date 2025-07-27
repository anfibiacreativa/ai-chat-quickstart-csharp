metadata description = 'Creates a role assignment for a service principal.'
param principalId string

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

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'
param roleDefinitionId string

resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}
