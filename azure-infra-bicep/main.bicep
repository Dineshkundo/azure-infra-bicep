// #####################################################################################################
// main.bicep - Modular Infrastructure
// #####################################################################################################

targetScope = 'resourceGroup'

// ==========================
// Deployment Flags (for selective deployments)
// ==========================
param deployKeyVault bool = true
param deployNetworking bool = true
param deployStorage bool = true
param deployVMs bool = true
param deployAKS bool = true
param deploySQL bool = true

// ==========================
// Core Parameters
// ==========================
param location string = resourceGroup().location

param keyVaultConfig object
param vmConfig object
param storageConfig object
param vnetConfig object

@description('Name of the existing Key Vault')
param keyVaultName string

@secure()
param secrets object

param nsgPublicSubnetId string
param nsgPrivateSubnetId string
param rtFirewallMgmtId string
param rtAksOnPremId string
param remoteVnetId string

param vms array
param vmConfigs array

// #####################################################################################################
// Key Vault
// #####################################################################################################
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

module kv './modules/security/keyvault.bicep' = if (deployKeyVault) {
  name: 'deployKeyVault'
  params: { config: keyVaultConfig }
}

output keyVaultId string = deployKeyVault ? kv.outputs.keyVaultId : ''
output keyVaultName string = deployKeyVault ? kv.outputs.keyVaultName : ''
output keyVaultUri string = deployKeyVault ? kv.outputs.keyVaultUri : ''

// #####################################################################################################
// Networking
// #####################################################################################################
module vnet './modules/networking/vnet.bicep' = if (deployNetworking) {
  name: 'deployVNet'
  params: {
    config: union(vnetConfig, {
      nsgPublicSubnetId: nsgPublicSubnetId
      nsgPrivateSubnetId: nsgPrivateSubnetId
      rtFirewallMgmtId: rtFirewallMgmtId
      rtAksOnPremId: rtAksOnPremId
      remoteVnetId: remoteVnetId
    })
  }
}

output vnetId string = deployNetworking ? vnet.outputs.vnetId : ''
output subnet1Id string = deployNetworking ? vnet.outputs.subnet1Id : ''
output subnetIds array = deployNetworking ? vnet.outputs.subnetIds : []

// #####################################################################################################
// Storage Account
// #####################################################################################################
module storage './modules/storage/storage-account.bicep' = if (deployStorage) {
  name: 'storageModule'
  params: { storageConfig: storageConfig }
}

output storageAccountId string = deployStorage ? storage.outputs.storageAccountResourceId : ''
output storagePrincipalId string = deployStorage ? storage.outputs.principalId : ''
output storageAccountName string = deployStorage ? storage.outputs.storageAccountName : ''

// #####################################################################################################
// Virtual Machines
// #####################################################################################################
module vm './modules/virtual-machine/vm.bicep' = if (deployVMs) {
  name: 'deployVM'
  params: { vmConfig: vmConfig, secrets: secrets }
}

output vmId string = deployVMs ? vm.outputs.vmId : ''
output vmName string = deployVMs ? vm.outputs.vmName : ''
output nicId string = deployVMs ? vm.outputs.nicId : ''

module MatchingService './modules/virtual-machine/Matching_Service_QA_Backup.bicep' = if (deployVMs) [for vm in vmConfigs: {
  name: '${vm.name}-deploy'
  params: {
    name: vm.name
    location: vm.location
    tags: vm.tags
    vmSize: vm.vmSize
    image: vm.image
    osDisk: vm.osDisk
    dataDisks: vm.dataDisks
    nicId: vm.nicId
    security: vm.security
    diagnostics: vm.diagnostics
    zone: vm.zone

    // Key Vault secrets
    adminUsername: keyVault.getSecret(vm.adminUsernameSecret)
    extensionUsername: keyVault.getSecret(vm.extensionSecrets.username)
    extensionPassword: keyVault.getSecret(vm.extensionSecrets.password)
    extensionSshKey: keyVault.getSecret(vm.extensionSecrets.ssh_key)
    extensionResetSsh: keyVault.getSecret(vm.extensionSecrets.reset_ssh)
    extensionRemoveUser: keyVault.getSecret(vm.extensionSecrets.remove_user)
    extensionExpiration: keyVault.getSecret(vm.extensionSecrets.expiration)
  }
}]

// RHEL Dev/QA VMs
module vmRHELDevQa './modules/virtual-machine/RHELDevQa.bicep' = if (deployVMs) [for vm in vms: {
  name: 'deploy-${vm.vmName}'
  params: {
    vmName: vm.vmName
    location: vm.location
    tags: vm.tags
    vmSize: vm.vmSize
    publisher: vm.publisher
    offer: vm.offer
    sku: vm.sku
    version: vm.version
    osDiskId: vm.osDiskId
    dataDiskId: vm.dataDiskId
    nicId: vm.nicId
    extensions_enablevmAccess_username: vm.extensions.username
    extensions_enablevmAccess_password: vm.extensions.password
    extensions_enablevmAccess_ssh_key: vm.extensions.ssh_key
    extensions_enablevmAccess_reset_ssh: vm.extensions.reset_ssh
    extensions_enablevmAccess_remove_user: vm.extensions.remove_user
    extensions_enablevmAccess_expiration: vm.extensions.expiration
  }
}]

// #####################################################################################################
// Boomi / Matching Service / RedhatServerUAT
// #####################################################################################################
module Boomi './modules/virtual-machine/Boomi_Integration.bicep' = if (deployVMs) [for vm in vms: {
  name: 'deploy-${vm.name}'
  params: { location: location, vmConfig: vm }
}]

module Matching_Service './modules/virtual-machine/Matching_Service.bicep' = if (deployVMs) [for vm in vms: {
  name: 'deploy-${vm.name}'
  params: { location: location, vmConfig: vm }
}]

module RedhatServerUAT './modules/virtual-machine/RedhatServerUAT.bicep' = if (deployVMs) [for vm in vmConfigs: {
  name: '${vm.name}-deployment'
  params: { vmConfig: vm, location: location }
}]

// #####################################################################################################
// AKS & SQL (optional)
// #####################################################################################################
// module aks './modules/cluster/aks.bicep' = if (deployAKS) { ... }
// module sql './modules/data-factory/sql.bicep' = if (deploySQL) { ... }
