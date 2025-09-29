// //// Main Virtual Machine//
targetScope = 'resourceGroup'
@description('Tag suffix for resource tagging')
param tagSuffix string
// param location string = resourceGroup().location

// param keyVaultConfig object
param vmConfig object

@secure()
param secrets object

module vm './modules/virtual-machine/Jenkins.bicep' = {
  name: 'deployVM'
  params: {
    vmConfig: vmConfig
    secrets: secrets
    tagSuffix: tagSuffix

  }
}

output vmId string = vm.outputs.vmId
output vmName string = vm.outputs.vmName
output nicId string = vm.outputs.nicId
