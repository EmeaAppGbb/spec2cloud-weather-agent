@description('The principal ID to assign the role to')
param principalId string

@description('The type of principal')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'

@description('The role definition ID to assign')
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

output id string = roleAssignment.id
output name string = roleAssignment.name
