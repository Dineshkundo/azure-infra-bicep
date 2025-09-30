@description('Key Vault configuration object')
param config object

@description('Tag suffix for resource tagging')
param tagSuffix string

// ==========================
// Resource: Key Vault
// ==========================
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: config.name
  location: config.location
  tags: union(config.tags, {
    Environment: tagSuffix
  })
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: config.tenantId
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        for subnetName in config.subnetNames: {
          id: '${config.vnetResourceId}/subnets/${subnetName}'
        }
      ]
      ipRules: [
        for ip in config.allowedIPs: {
          value: ip
        }
      ]
    }
    accessPolicies: [
      for objectId in config.accessObjectIds: {
        tenantId: config.tenantId
        objectId: objectId
        permissions: {
          keys: [ 'get', 'wrapKey', 'unwrapKey' ]
          secrets: [ 'get', 'list', 'set' ]
          certificates: [ 'get' ]
        }
      }
    ]
  }
}

// ==========================
// Loop: Secrets
// ==========================
resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in config.secrets: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]

// ==========================
// Outputs
// ==========================
output keyVaultId string   = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string  = keyVault.properties.vaultUri
