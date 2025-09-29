@description('VM Name')
param name string

@description('Location')
param location string

@description('Tags')
param tags object

@description('VM Size')
param vmSize string

@description('Image reference')
param image object

@description('OS Disk settings')
param osDisk object

@description('Data disks')
param dataDisks array

@description('NIC Id')
param nicId string

@description('Security settings')
param security object

@description('Diagnostics settings')
param diagnostics object

@description('Availability zone')
param zone string

// 🔑 Secure values from Key Vault
@secure()
param adminUsername string

@secure()
param extensionUsername string

@secure()
param extensionPassword string

@secure()
param extensionSshKey string

@secure()
param extensionResetSsh string

@secure()
param extensionRemoveUser string

@secure()
param extensionExpiration string

// ---------------- VM Resource ----------------
resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: name
  location: location
  tags: tags
  zones: [
    zone
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: image.publisher
        offer: image.offer
        sku: image.sku
        version: image.version
      }
      osDisk: {
        osType: 'Linux'
        name: osDisk.name
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: osDisk.storageAccountType
          id: osDisk.id
        }
        diskSizeGB: osDisk.sizeGB
      }
      dataDisks: [
        for disk in dataDisks: {
          lun: disk.lun
          name: disk.name
          createOption: disk.createOption
          caching: disk.caching
          managedDisk: {
            storageAccountType: disk.storageAccountType
            id: disk.id
          }
          deleteOption: disk.deleteOption
          diskSizeGB: disk.sizeGB
        }
      ]
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/adminuser/.ssh/authorized_keys'
              keyData: extensionSshKey
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
          assessmentMode: 'AutomaticByPlatform'
        }
      }
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      encryptionAtHost: security.encryptionAtHost
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: diagnostics.bootEnabled
      }
    }
  }
}

// ---------------- Extension ----------------
resource vmAccess 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
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
      username: extensionUsername
      password: extensionPassword
      ssh_key: extensionSshKey
      reset_ssh: extensionResetSsh
      remove_user: extensionRemoveUser
      expiration: extensionExpiration
    }
  }
}
