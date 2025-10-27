param location string
param clusterName string
param vnetResourceId string
param sshPublicKey string
param adminUsername string
param systemPool object
param userPools array
param serviceCidr string
param dnsServiceIP string
param kubernetesVersion string
param authorizedIpRanges array
param tagSuffix string

// -----------------------------
// AKS Cluster Resource
// -----------------------------
resource aks 'Microsoft.ContainerService/managedClusters@2025-01-01' = {
  name: clusterName
  location: location

  tags: {
    environment: tagSuffix
    cluster: clusterName
  }

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: clusterName
    enableRBAC: true
    disableLocalAccounts: false

    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          { keyData: sshPublicKey }
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
      authorizedIPRanges: authorizedIpRanges
    }

    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'Standard'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      outboundType: 'loadBalancer'
    }

    agentPoolProfiles: [
      {
        name: systemPool.name
        vmSize: systemPool.vmSize
        count: systemPool.count
        minCount: systemPool.minCount
        maxCount: systemPool.maxCount
        enableAutoScaling: true
        mode: systemPool.mode
        osType: 'Linux'
        osSKU: 'Ubuntu'
        vnetSubnetID: '${vnetResourceId}/subnets/${systemPool.subnetName}'
        maxPods: systemPool.maxPods
      }
    ]
  }
}

// -----------------------------
// User Node Pools
// -----------------------------
module userNodePools './nodePool.bicep' = [for pool in userPools: {
  name: '${clusterName}-${pool.name}'
  params: {
    pool: pool
    vnetResourceId: vnetResourceId
    tagSuffix: tagSuffix
    clusterName: clusterName
  }
  dependsOn: [
    aks
  ]
}]
