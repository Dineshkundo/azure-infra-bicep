@secure()
param extensions_enablevmAccess_username string
@secure()
param extensions_enablevmAccess_password string
@secure()
param extensions_enablevmAccess_ssh_key string
@secure()
param extensions_enablevmAccess_reset_ssh string
@secure()
param extensions_enablevmAccess_remove_user string
@secure()
param extensions_enablevmAccess_expiration string

param vmName string
param location string
param tags object
param vmSize string
param publisher string
param offer string
param sku string
param version string
param osDiskId string
param dataDiskId string
param nicId string

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: version
      }
      osDisk: {
        osType: 'Linux'
        name: '${vmName}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          id: osDiskId
        }
        deleteOption: 'Detach'
        diskSizeGB: 64
      }
      dataDisks: [
        {
          lun: 0
          name: '${vmName}-datadisk1'
          createOption: 'Attach'
          caching: 'None'
          managedDisk: {
            id: dataDiskId
          }
          deleteOption: 'Detach'
          diskSizeGB: 64
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: extensions_enablevmAccess_username
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}

resource enableVmAccess 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: vm
  name: 'enablevmAccess'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.OSTCExtensions'
    type: 'VMAccessForLinux'
    typeHandlerVersion: '1.5'
    settings: {}
    protectedSettings: {
      username: extensions_enablevmAccess_username
      password: extensions_enablevmAccess_password
      ssh_key: extensions_enablevmAccess_ssh_key
      reset_ssh: extensions_enablevmAccess_reset_ssh
      remove_user: extensions_enablevmAccess_remove_user
      expiration: extensions_enablevmAccess_expiration
    }
  }
}
output vmId string = vm.id
output vmName string = vm.name  
