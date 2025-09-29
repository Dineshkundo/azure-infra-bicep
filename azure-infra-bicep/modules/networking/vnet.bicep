targetScope = 'resourceGroup'

@description('Full VNet configuration object')
param config object

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: config.vnetName
  location: config.location
  tags: config.tags
  properties: {
    addressSpace: {
      addressPrefixes: config.addressSpace
    }
    subnets: [
      for subnet in config.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.prefix
          networkSecurityGroup: contains(subnet, 'nsgId') ? { id: subnet.nsgId } : null
          routeTable: contains(subnet, 'routeTableId') ? { id: subnet.routeTableId } : null
        }
      }
    ]
    virtualNetworkPeerings: contains(config, 'remoteVnetId') && !empty(config.remoteVnetId) ? [
      {
        name: '${config.vnetName}-peering'
        properties: {
          remoteVirtualNetwork: { id: config.remoteVnetId }
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: true
          allowGatewayTransit: true
          useRemoteGateways: false
        }
      }
    ] : []
  }
}

output vnetId string = vnet.id
output subnetIds array = [for s in config.subnets: '${vnet.id}/subnets/${s.name}']
output subnet1Id string = vnet.properties.subnets[0].id

