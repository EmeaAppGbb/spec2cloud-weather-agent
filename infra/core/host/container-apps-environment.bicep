param name string
param location string = resourceGroup().location
param tags object = {}

@description('Resource ID of the Log Analytics workspace for diagnostics')
param logAnalyticsWorkspaceId string = ''

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: !empty(logAnalyticsWorkspaceId) ? {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
      }
    } : null
  }
}

output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
output name string = containerAppsEnvironment.name
output id string = containerAppsEnvironment.id
