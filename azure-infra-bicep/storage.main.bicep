param storageConfig object
param tagSuffix string

module storage './modules/storage/storage-account.bicep' = {
  name: 'storageModule'
  params: {
    storageConfig: storageConfig
    tagSuffix: tagSuffix

  }
}

output storageAccountResourceId string = storage.outputs.storageAccountResourceId
output storageAccountName string = storage.outputs.storageAccountName
output principalId string = storage.outputs.principalId
output tags object = storage.outputs.tags
