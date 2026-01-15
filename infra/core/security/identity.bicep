@description('The name of the user assigned managed identity')
param name string

@description('The location for the identity')
param location string = resourceGroup().location

@description('Tags to apply to the identity')
param tags object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output id string = userAssignedIdentity.id
output name string = userAssignedIdentity.name
output principalId string = userAssignedIdentity.properties.principalId
output clientId string = userAssignedIdentity.properties.clientId
