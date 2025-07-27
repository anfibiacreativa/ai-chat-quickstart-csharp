metadata description = 'Creates an Azure Key Vault instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
param principalId string

@description('Enables the vault for deployment by Azure Resource Manager')
param enabledForDeployment bool = false

@description('Enables the vault for template deployment by Azure Resource Manager')
param enabledForTemplateDeployment bool = true

@description('Enables the vault for disk encryption by Azure Virtual Machines')
param enabledForDiskEncryption bool = false

@description('Enable purge protection for the vault')
param enablePurgeProtection bool = false

@description('Enable RBAC authorization for the vault')
param enableRbacAuthorization bool = true

@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'

param accessPolicies array = []

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: sku
    }
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enablePurgeProtection: enablePurgeProtection ? true : null
    enableRbacAuthorization: enableRbacAuthorization
    accessPolicies: !enableRbacAuthorization ? accessPolicies : null
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Grant Key Vault Secrets User role to the principal
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  scope: keyVault
  name: guid(keyVault.id, principalId, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7') // Key Vault Secrets User
    principalType: 'User'
  }
}

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri