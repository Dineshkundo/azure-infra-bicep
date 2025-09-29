// ==========================
// module/storage/storage.bicep
// Secure Storage Account Module (config-driven)
// ==========================

@description('Storage configuration object')
param storageConfig object

// ==========================
// Storage Account
// ==========================
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageConfig.storageAccountName
  location: storageConfig.location
  sku: {
    name: storageConfig.sku.name
  }
  kind: storageConfig.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false // 🔒 Disable shared key, rely on RBAC/Managed Identity
    largeFileSharesState: 'Enabled'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
    encryption: {
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: storageConfig.accessTier
    networkAcls: {
      bypass: 'AzureServices'
      resourceAccessRules: [
        for factoryId in storageConfig.factoryResourceIds: {
          tenantId: subscription().tenantId
          resourceId: factoryId
        }
      ]
      virtualNetworkRules: [
        for subnetId in storageConfig.subnetIds: {
          id: subnetId
          action: 'Allow'
        }
      ]
      ipRules: [
        for ip in storageConfig.allowedIpAddresses: {
          value: ip
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
  }
}

// ==========================
// Blob Service
// ==========================
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

// Blob Containers (from config)
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = [
  for containerName in storageConfig.blobContainers: {
    parent: blobService
    name: containerName
    properties: {
      publicAccess: 'None'
    }
  }
]

// ==========================
// File Service
// ==========================
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

// File Shares (from config)
resource shares 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-01-01' = [
  for shareName in storageConfig.fileShares: {
    parent: fileService
    name: shareName
    properties: {
      accessTier: 'TransactionOptimized'
      shareQuota: 102400
      enabledProtocols: 'SMB'
    }
  }
]

// ==========================
// Outputs
// ==========================
output storageAccountResourceId string = storageAccount.id
output storageAccountName string = storageAccount.name
output principalId string = storageAccount.identity.principalId
