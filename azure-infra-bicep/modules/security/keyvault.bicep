param config object

resource kv 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: config.keyVaultName
  location: config.location
  tags: config.tags
  properties: {
    sku: {
      name: config.sku.name
      family: config.sku.family
    }
    tenantId: config.tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [for ip in config.allowedIpAddresses: { value: ip }]
      virtualNetworkRules: [for id in config.subnetIds: { id: id }]
    }
    accessPolicies: config.accessPolicies
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
  }
}

output keyVaultId string = kv.id
output keyVaultName string = kv.name
output keyVaultUri string = kv.properties.vaultUri
