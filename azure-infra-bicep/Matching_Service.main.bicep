///// Matching Service VM deployments
///
param vms array
param location string
module Matching_Service './modules/virtual-machine/Matching_Service.bicep' = [for vm in vms: {
  name: 'deploy-${vm.name}'
  params: {
    location: location
    vmConfig: vm
  }
}]
