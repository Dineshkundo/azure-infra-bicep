targetScope = 'resourceGroup'

param vmConfig object
@secure()
param secrets object

// Create NIC
resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: '${vmConfig.vmName}-nic'
  location: vmConfig.location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vmConfig.subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Create VM
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmConfig.vmName
  location: vmConfig.location
  zones: empty(vmConfig.zone) ? [] : [vmConfig.zone]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmConfig.vmSize
    }
    storageProfile: {
      imageReference: vmConfig.imageReference
      osDisk: {
        osType: 'Linux'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: vmConfig.osDiskType
        }
        diskSizeGB: vmConfig.osDiskSizeGB
      }
    }
    osProfile: {
      computerName: vmConfig.vmName
      adminUsername: secrets.adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${secrets.adminUsername}/.ssh/authorized_keys'
              keyData: secrets.sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// VM Access Extension (Optional)
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (!empty(secrets.extensions_username)) {
  parent: vm
  name: 'enablevmAccess'
  location: vmConfig.location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.OSTCExtensions'
    type: 'VMAccessForLinux'
    typeHandlerVersion: '1.5'
    settings: {}
    protectedSettings: {
      username: secrets.extensions_username
      ssh_key: secrets.extensions_ssh_key
      reset_ssh: secrets.extensions_reset_ssh
      remove_user: secrets.extensions_remove_user
      expiration: secrets.extensions_expiration
    }
  }
}

// Outputs
output vmId string = vm.id
output vmName string = vm.name
output nicId string = nic.id
