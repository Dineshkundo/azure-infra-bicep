param location string
param aksConfig object
param tagSuffix string

resource aks 'Microsoft.ContainerService/managedClusters@2025-01-01' = {
  name: aksConfig.clusterName
  location: location

  tags: {
    environment: tagSuffix
    cluster: aksConfig.clusterName
  }

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    kubernetesVersion: aksConfig.kubernetesVersion
    dnsPrefix: aksConfig.clusterName
    enableRBAC: true
    disableLocalAccounts: false

    linuxProfile: {
      adminUsername: aksConfig.adminUsername
      ssh: {
        publicKeys: [
          { keyData: aksConfig.sshPublicKey }
        ]
      }
    }

    oidcIssuerProfile: {
      enabled: true
    }

    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }

    apiServerAccessProfile: {
      authorizedIPRanges: aksConfig.authorizedIpRanges
    }

    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'Standard'
      serviceCidr: aksConfig.serviceCidr
      dnsServiceIP: aksConfig.dnsServiceIP
      outboundType: 'loadBalancer'
    }

    agentPoolProfiles: [
      {
        name: aksConfig.systemPool.name
        vmSize: aksConfig.systemPool.vmSize
        count: aksConfig.systemPool.count
        minCount: aksConfig.systemPool.minCount
        maxCount: aksConfig.systemPool.maxCount
        enableAutoScaling: true
        mode: aksConfig.systemPool.mode
        osType: 'Linux'
        osSKU: 'Ubuntu'
        vnetSubnetID: '${aksConfig.vnetResourceId}/subnets/${aksConfig.systemPool.subnetName}'
        maxPods: aksConfig.systemPool.maxPods
      }
    ]
  }
}

module userNodePools './nodePool.bicep' = [for pool in aksConfig.userPools: {
  name: '${aksConfig.clusterName}-${pool.name}'
  params: {
    pool: pool
    vnetResourceId: aksConfig.vnetResourceId
    tagSuffix: tagSuffix
    clusterName: aksConfig.clusterName
  }
  dependsOn: [
    aks
  ]
}]
