targetScope = 'resourceGroup'

// ==========================
// Parameters
// ==========================
param vmConfig object


@description('Tag suffix for resource tagging')
param tagSuffix string

// -----------------------------------------------------------
// ✅ Reference your existing Key Vault (CODADEV)
// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'CODADEV'
}

// Retrieve SSH public key
var sshPublicKey = listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVault.name, 'sshPublicKey'), '2019-09-01').value

// ==========================
// Compute subnetId dynamically
// ==========================
//var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vmConfig.vnetName, vmConfig.subnetName)

// ==========================
// NIC resource
// ==========================
resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: '${vmConfig.vmName}-nic'
  location: vmConfig.location
  tags: {
    environment: tagSuffix
    createdBy: 'iac-bicep'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: vmConfig.subnetId }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// ==========================
// VM resource
// ==========================

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmConfig.vmName
  location: vmConfig.location
  zones: empty(vmConfig.?zone) ? [] : [vmConfig.zone]
  identity: { type: 'SystemAssigned' }
  tags: {
    environment: tagSuffix
    createdBy: 'iac-bicep'
  }
  properties: {
    hardwareProfile: { vmSize: vmConfig.vmSize }
    storageProfile: {
      imageReference: vmConfig.imageReference
      osDisk: {
        osType: vmConfig.osType
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: { storageAccountType: vmConfig.osDiskType }
        diskSizeGB: vmConfig.osDiskSizeGB
        deleteOption: vmConfig.deleteOption
      }
    }
    osProfile: {
      computerName: vmConfig.vmName
      adminUsername: vmConfig.adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            { path: '/home/${vmConfig.adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey }
          ]
        }
      }
    }
    networkProfile: { networkInterfaces: [{ id: nic.id }] }
  }
}


// ==========================
// Outputs
// ==========================
output vmId string = vm.id
output vmName string = vm.name
output nicId string = nic.id
output tags object = vm.tags
output principalId string = vm.identity.principalId
output location string = vm.location
output vmSize string = vm.properties.hardwareProfile.vmSize
output osDiskType string = vm.properties.storageProfile.osDisk.managedDisk.storageAccountType
output osDiskSizeGB int = vm.properties.storageProfile.osDisk.diskSizeGB
output imageReference object = vm.properties.storageProfile.imageReference
output privateIP string = nic.properties.ipConfigurations[0].properties.privateIPAddress
