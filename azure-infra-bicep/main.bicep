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
  'RHELDevQa'
  'RedhatServerUAT'
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


/////////////////////// Key Vault Module  /////


module kv './modules/security/keyvault.bicep' = if (serviceName == 'keyvault') {
  name: 'deployKeyVault'
  params: {
    config: vmConfig.keyVault
    tagSuffix: tagSuffix
  }
}




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
    tagSuffix: tagSuffix
  }
}]

/// ///////////////////////////////////////////////////////////
//               RHELDevQa  
///////////////////////////////////////////////////////////////

var vmsToDeployRHELDevQa = serviceName == 'RHELDevQa' ? vms : []
module vmRHELDevQa './modules/virtual-machine/RHELDevQa.bicep' = [for vm in vmsToDeployRHELDevQa: {
  name: 'deploy-${vm.vmName}-${tagSuffix}'
  params: {
    vmConfig: vm
    tagSuffix: tagSuffix
  }
}]

////////////////////////////////////////////////////////////////////
///// RedhatServerUAT ///
///////////////////////////////////////////////////////////////////          


var vmsToDeployUAT = serviceName == 'RedhatServerUAT' ? vms : []

module RedhatServerUAT './modules/virtual-machine/RedhatServerUAT.bicep' = [for vm in vmsToDeployUAT: {
  name: '${vm.name}-deployment'
  params: {
    vmConfig: vm
    location: location
    tagSuffix: tagSuffix
  }
}]









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
