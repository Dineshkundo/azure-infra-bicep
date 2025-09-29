// // //#####################################################################################################
// // iac/
// // ├── main.bicep                     # Orchestration file calling all modules
// // ├── output.bicep                   # Optional, central outputs
// // ├── modules/                       # All reusable modules
// // │   ├── keyvault.bicep             # Key Vault module
// // │   ├── virtual-machine.bicep      # VM module
// // │   ├── network.bicep              # VNet + subnets module
// // │   ├── storage.bicep              # Storage account + containers/shares
// // │   ├── aks.bicep                  # AKS cluster module
// // │   └── others/                    # Any other resource modules
// // ├── variables/                     # Environment-specific parameter files
// // │   ├── dev.parameters.json
// // │   ├── uat.parameters.json
// // │   ├── prod.parameters.json
// // │   ├── dev.vm.variables.json      # Optional: separate VM variables if many VMs
// // │   └── ...
// // ├── scripts/                       # Any scripts used by Jenkins / pre/post deployments
// // │   └── create-keyvault-secrets.sh
// // ├── output/                        # Optional: store outputs
// // │   ├── dev.output.json
// // │   ├── uat.output.json
// // │   └── prod.output.json
// // └── Jenkinsfile                    # CI/CD pipeline
// //#####################################################################################################



targetScope = 'resourceGroup'
// param location string = resourceGroup().location

param keyVaultConfig object
// param vmConfig object
// param vnetConfig object

// // Name of the existing key vault (all VMs use the same KV for secrets)
// @description('Name of Key Vault that already contains the secrets')
// param keyVaultName string

// resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
//   name: keyVaultName
// }

module kv './modules/security/keyvault.bicep' = {
  name: 'deployKeyVault'
  params: {
    config: keyVaultConfig
  }
}
output keyVaultId string = kv.outputs.keyVaultId
output keyVaultName string = kv.outputs.keyVaultName
output keyVaultUri string = kv.outputs.keyVaultUri

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

// //// Storage Account Module

param storageConfig object

module storage './modules/storage/storage-account.bicep' = {
  name: 'storageModule'
  params: {
    storageConfig: storageConfig
  }
}


output storageAccountId string = storage.outputs.storageAccountResourceId
output storagePrincipalId string = storage.outputs.principalId
output storageAccountName string = storage.outputs.storageAccountName

// //// Virtual Machine//


// @secure()
// param secrets object

// module vm './modules/virtual-machine/vm.bicep' = {
//   name: 'deployVM'
//   params: {
//     vmConfig: vmConfig
//     secrets: secrets
//   }
// }

// output vmId string = vm.outputs.vmId
// output vmName string = vm.outputs.vmName
// output nicId string = vm.outputs.nicId


// ///////////////////////////////////////////////////////////

// // Deploy VMs from configs
// module MatchingService './modules/virtual-machine/Matching_Service_QA_Backup.bicep' = [for vm in vmConfigs: {
//   name: '${vm.name}-deploy'
//   params: {
//     name: vm.name
//     location: vm.location
//     tags: vm.tags
//     vmSize: vm.vmSize
//     image: vm.image
//     osDisk: vm.osDisk
//     dataDisks: vm.dataDisks
//     nicId: vm.nicId
//     security: vm.security
//     diagnostics: vm.diagnostics
//     zone: vm.zone

//     // 🔑 Secure params from Key Vault
//     adminUsername: keyVault.getSecret(vm.adminUsernameSecret)
//     extensionUsername: keyVault.getSecret(vm.extensionSecrets.username)
//     extensionPassword: keyVault.getSecret(vm.extensionSecrets.password)
//     extensionSshKey: keyVault.getSecret(vm.extensionSecrets.ssh_key)
//     extensionResetSsh: keyVault.getSecret(vm.extensionSecrets.reset_ssh)
//     extensionRemoveUser: keyVault.getSecret(vm.extensionSecrets.remove_user)
//     extensionExpiration: keyVault.getSecret(vm.extensionSecrets.expiration)
//   }
// }]
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

// module Boomi './modules/virtual-machine/Boomi_Integration.bicep' = [for vm in vms: {
//   name: 'deploy-${vm.name}'
//   params: {
//     location: location
//     vmConfig: vm
//   }
// }]


// ///////////////////////////////////////////////////////////
// ///// Matching Service VM deployments
// ///

// module Matching_Service './modules/virtual-machine/Matching_Service.bicep' = [for vm in vms: {
//   name: 'deploy-${vm.name}'
//   params: {
//     location: location
//     vmConfig: vm
//   }
// }]


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
