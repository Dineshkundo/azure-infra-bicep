// // //#####################################################################################################
// // iac/
// // ├── main.bicep                     # Orchestration file calling all modules
// // ├── modules/                       # All reusable modules
// // │   ├── keyvault.bicep             # Key Vault module
// // │   ├── virtual-machine.bicep      # VM module
// // │   ├── network.bicep              # VNet + subnets module
// // │   ├── storage.bicep              # Storage account + containers/shares
// // │   ├── aks.bicep                  # AKS cluster module
// // │   └── others/                    # Any other resource modules
// // ├── parameters/                     # Environment-specific parameter files
// // │   ├── dev.parameters.json
// // │   ├── uat.parameters.json
// // │   ├── prod.parameters.json
// // │   ├── dev.vm.variables.json      # Optional: separate VM variables if many VMs
// // │   └── ...
// // └── Jenkinsfile                    # CI/CD pipeline
// //#####################################################################################################
targetScope = 'resourceGroup'

@allowed([
  'Jenkins-vm'
  'Matching-Service'
  'Matching-Service-QA-Backup'
  'Boomi_Integration'
  'storage'
  'network'
  'keyvault'
  'aks'
])
@description('Service to deploy')
param serviceName string

// Service-specific configurations
param vmConfig object = {}
param storageConfig object = {}

// Tag suffix
@description('Suffix for tags')
param tagSuffix string

// Secrets (optional)
@secure()
param secrets object = {}

// -------------------------
// Deploy VM if requested
// -------------------------
module vm './modules/virtual-machine/Jenkins.bicep' = if (serviceName == 'Jenkins-vm') {
  name: 'deployVM'
  params: {
    vmConfig: vmConfig
    secrets: secrets
    tagSuffix: tagSuffix
  }
}

// -------------------------
// Deploy Storage if requested
// -------------------------
module storage './modules/storage/storage-account.bicep' = if (serviceName == 'storage') {
  name: 'storageModule'
  params: {
    storageConfig: storageConfig
    tagSuffix: tagSuffix
  }
}


///// Matching Service VM deployments
///

param vms array
param location string

var vmsToDeploy = serviceName == 'Matching-Service' ? vms : []

module Matching_Service './modules/virtual-machine/Matching_Service.bicep' = [for vm in vmsToDeploy: {
  name: 'deploy-${vm.name}'
  params: {
    location: location
    vmConfig: vm
  }
}]

//

// ///////////////////////////////////////////////////////////
// Deploy Matching Service QA Backup VMs from configuration array  ////
// ///////////////////////////////////////////////////////////


var vmsToDeployQA = serviceName == 'Matching-Service-QA-Backup' ? vms : []

module MatchingService './modules/virtual-machine/Matching_Service_QA_Backup.bicep' = [for vm in vmsToDeployQA: {
  name: '${vm.name}-deploy'
  params: {
    location: location
    vmConfig: vm
  }
}]

/// ///////////////////////////////////////////////////////////
//               Boomi_Integration
///////////////////////////////////////////////////////////////

var vmsToDeployBoomi = serviceName == 'Boomi_Integration' ? vms : []

module Boomi './modules/virtual-machine/Boomi_Integration.bicep' = [for vm in vmsToDeployBoomi: {
  name: 'deploy-${vm.name}'
  params: {
    location: location
    vmConfig: vm
  }
}]

// -------------------------
// Additional modules (network, keyvault, aks)
// -------------------------
// module network './modules/network/network.bicep' = if (serviceName == 'network') { ... }
// module keyvault './modules/keyvault/keyvault.bicep' = if (serviceName == 'keyvault') { ... }
// module aks './modules/cluster/aks.bicep' = if (serviceName == 'aks') { ... }

// targetScope = 'resourceGroup'
// @description('Tag suffix for resource tagging')
// param tagSuffix string
// // param location string = resourceGroup().location

// // param keyVaultConfig object
// param vmConfig object
// param vnetConfig object

// // Name of the existing key vault (all VMs use the same KV for secrets)
// @description('Name of Key Vault that already contains the secrets')
// param keyVaultName string

// resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
//   name: keyVaultName
// }

// module kv './modules/security/keyvault.bicep' = {
//   name: 'deployKeyVault'
//   params: {
//     config: keyVaultConfig
//   }
// }
// output keyVaultId string = kv.outputs.keyVaultId
// output keyVaultName string = kv.outputs.keyVaultName
// output keyVaultUri string = kv.outputs.keyVaultUri

// //// Networking Module  

// param nsgPublicSubnetId string
// param nsgPrivateSubnetId string
// param rtFirewallMgmtId string
// param rtAksOnPremId string
// param remoteVnetId string

// module vnet './modules/networking/vnet.bicep' = {
//   name: 'deployVNet'
//   params: {
//     config: union(vnetConfig, {
//       nsgPublicSubnetId: nsgPublicSubnetId
//       nsgPrivateSubnetId: nsgPrivateSubnetId
//       rtFirewallMgmtId: rtFirewallMgmtId
//       rtAksOnPremId: rtAksOnPremId
//       remoteVnetId: remoteVnetId
//     })
//   }
// }

// output vnetId string = vnet.outputs.vnetId
// output subnet1Id string = vnet.outputs.subnet1Id
// output subnetIds array = vnet.outputs.subnetIds



// ///////////////////////////////////////////////////////////
// // RHEL Dev/QA VM deployments
// @description('Array of VM configurations')
// param vms array

// module vmRHELDevQa './modules/virtual-machine/RHELDevQa.bicep' = [for vm in vms: {
//   name: 'deploy-${vm.vmName}'
//   params: {
//     vmName: vm.vmName
//     location: vm.location
//     tags: vm.tags
//     vmSize: vm.vmSize
//     publisher: vm.publisher
//     offer: vm.offer
//     sku: vm.sku
//     version: vm.version
//     osDiskId: vm.osDiskId
//     dataDiskId: vm.dataDiskId
//     nicId: vm.nicId
//     extensions_enablevmAccess_username: vm.extensions.username
//     extensions_enablevmAccess_password: vm.extensions.password
//     extensions_enablevmAccess_ssh_key: vm.extensions.ssh_key
//     extensions_enablevmAccess_reset_ssh: vm.extensions.reset_ssh
//     extensions_enablevmAccess_remove_user: vm.extensions.remove_user
//     extensions_enablevmAccess_expiration: vm.extensions.expiration
//   }
// }]


// ///////////////////////////////////////////////////////////







// ////////////////////////////////////////////////////////////////////
// ///// RedhatServerUAT ///
// ///          
// @description('Array of VM configurations')
// param vmConfigs array 

// module RedhatServerUAT './modules/virtual-machine/RedhatServerUAT.bicep' = [for vm in vmConfigs: {
//   name: '${vm.name}-deployment'
//   params: {
//     vmConfig: vm
//     location: location
//   }
// }]
// //// AKS and SQL Modules
// // module aks './modules/cluster/aks.bicep' = {
// //   name: 'deployAKS'
// //   params: {
// //     clusterName: aksConfig.clusterName
// //     nodeCount: aksConfig.nodeCount
// //     nodeSize: aksConfig.nodeSize
// //     servicePrincipalSecretName: aksConfig.servicePrincipalSecretName
// //     keyVaultName: keyVaultConfig.keyVaultName
// //     location: location
// //   }
// // }

// // module sql './modules/data-factory/sql.bicep' = {
// //   name: 'deploySQL'
// //   params: {
// //     sqlServerName: sqlConfig.sqlServerName
// //     databaseName: sqlConfig.databaseName
// //     adminUser: sqlConfig.adminUser
// //     adminPasswordSecretName: sqlConfig.adminPasswordSecretName
// //     keyVaultName: keyVaultConfig.keyVaultName
// //     location: location
// //   }
// // }



// // output aksId string = aks.outputs.aksId
// // output sqlConnection string = sql.outputs.sqlConnectionString
