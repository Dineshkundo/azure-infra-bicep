param pool object
param vnetResourceId string
param clusterName string

resource nodepool 'Microsoft.ContainerService/managedClusters/agentPools@2025-01-01' = {
  name: '${clusterName}/${pool.name}'
  dependsOn: [
    resourceId('Microsoft.ContainerService/managedClusters', clusterName)
  ]
  properties: {
    vmSize: pool.vmSize
    count: pool.count
    minCount: pool.minCount
    maxCount: pool.maxCount
    enableAutoScaling: true
    mode: pool.mode
    osType: 'Linux'
    osSKU: 'Ubuntu'
    vnetSubnetID: '${vnetResourceId}/subnets/${pool.subnetName}'
    maxPods: pool.maxPods
  }
}
