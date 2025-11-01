targetScope = 'resourceGroup'

@description('Jenkins VM configuration')
param vmConfig object

@description('Tag suffix for tagging')
param tagSuffix string

@description('Existing Key Vault name')
param keyVaultName string

// ----------------------------------------
// Get SSH key from Key Vault
// ----------------------------------------
var sshPublicKey = listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, 'sshPublicKey'), '2019-09-01').value

// ----------------------------------------
// Reference existing subnet in existing VNet
// ----------------------------------------
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vmConfig.vnetName, vmConfig.subnetName)

// ----------------------------------------
// Network Interface
// ----------------------------------------
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
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// ----------------------------------------
// Virtual Machine
// ----------------------------------------
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmConfig.vmName
  location: vmConfig.location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    environment: tagSuffix
    createdBy: 'iac-bicep'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmConfig.vmSize
    }
    storageProfile: {
      imageReference: vmConfig.imageReference
      osDisk: {
        osType: vmConfig.osType
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: vmConfig.osDiskType
        }
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
            {
              path: '/home/${vmConfig.adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: nic.id }
      ]
    }
  }
}

// ----------------------------------------
// Outputs
// ----------------------------------------
output vmId string = vm.id
output vmName string = vm.name
output privateIP string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output principalId string = vm.identity.principalId
