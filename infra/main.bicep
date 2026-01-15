targetScope = 'subscription'
// targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@maxLength(90)
@description('Name of the resource group to use or create')
param resourceGroupName string = 'rg-${environmentName}'

// Restricted locations to match list from
// https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/responses?tabs=python-key#region-availability
@minLength(1)
@description('Primary location for all resources')
@allowed([
  'australiaeast'
  'brazilsouth'
  'canadacentral'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'germanywestcentral'
  'italynorth'
  'japaneast'
  'koreacentral'
  'northcentralus'
  'norwayeast'
  'polandcentral'
  'southafricanorth'
  'southcentralus'
  'southeastasia'
  'southindia'
  'spaincentral'
  'swedencentral'
  'switzerlandnorth'
  'uaenorth'
  'uksouth'
  'westus'
  'westus2'
  'westus3'
])
param location string

@metadata({azd: {
  type: 'location'
  usageName: [
    'OpenAI.GlobalStandard.gpt-4o-mini,10'
  ]}
})
param aiDeploymentsLocation string

@description('Id of the user or app to assign application roles')
param principalId string

@description('Principal type of user or app')
param principalType string

@description('Optional. Name of an existing AI Services account within the resource group. If not provided, a new one will be created.')
param aiFoundryResourceName string = ''

@description('Optional. Name of the AI Foundry project. If not provided, a default name will be used.')
param aiFoundryProjectName string = 'ai-project-${environmentName}'

@description('List of model deployments')
param aiProjectDeploymentsJson string = '[{\'name\':\'gpt-4.1-mini\',\'model\':{\'name\':\'gpt-4.1-mini\',\'format\':\'OpenAI\',\'version\':\'2025-04-14\'},\'sku\':{\'name\':\'GlobalStandard\',\'capacity\':30}}]'

@description('List of connections')
param aiProjectConnectionsJson string = '[]'

@description('List of resources to create and connect to the AI project')
param aiProjectDependentResourcesJson string = '[]'

var aiProjectDeployments = json(aiProjectDeploymentsJson)
var aiProjectConnections = json(aiProjectConnectionsJson)
var aiProjectDependentResources = json(aiProjectDependentResourcesJson)

@description('Enable hosted agent deployment')
param enableHostedAgents bool

@description('Enable monitoring for the AI project')
param enableMonitoring bool = true

// Container Apps parameters
@description('Enable Container Apps deployment for frontend, backend, and MCP server')
param enableContainerApps bool = false

@description('Container image name for frontend service')
param frontendImageName string = ''

@description('Container image name for backend service')
param backendImageName string = ''

@description('Container image name for MCP server service')
param mcpServerImageName string = ''

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Check if resource group exists and create it if it doesn't
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Build dependent resources array conditionally
// Check if ACR already exists in the user-provided array to avoid duplicates
var hasAcr = contains(map(aiProjectDependentResources, r => r.resource), 'registry')
var dependentResources = (enableHostedAgents) && !hasAcr ? union(aiProjectDependentResources, [
  {
    resource: 'registry'
    connectionName: 'acr-connection'
  }
]) : aiProjectDependentResources

// AI Project module
module aiProject 'core/ai/ai-project.bicep' = {
  scope: rg
  name: 'ai-project'
  params: {
    tags: tags
    location: aiDeploymentsLocation
    aiFoundryProjectName: aiFoundryProjectName
    principalId: principalId
    principalType: principalType
    existingAiAccountName: aiFoundryResourceName
    deployments: aiProjectDeployments
    connections: aiProjectConnections
    additionalDependentResources: dependentResources
    enableMonitoring: enableMonitoring
    enableHostedAgents: enableHostedAgents
  }
}

// Load abbreviations for naming
var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = uniqueString(subscription().id, resourceGroupName, location)

// User Assigned Identity for Container Apps
module containerAppsIdentity 'core/security/identity.bicep' = if (enableContainerApps) {
  scope: rg
  name: 'container-apps-identity'
  params: {
    name: 'id-${environmentName}'
    location: location
    tags: tags
  }
}

// Container Apps Environment
module containerAppsEnvironment 'core/host/container-apps-environment.bicep' = if (enableContainerApps) {
  scope: rg
  name: 'container-apps-environment'
  params: {
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    tags: tags
  }
}

// Frontend Container App (external - weather-themed chat UI)
module frontendContainerApp 'core/host/container-app.bicep' = if (enableContainerApps) {
  scope: rg
  name: 'frontend-container-app'
  params: {
    name: '${abbrs.appContainerApps}frontend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'frontend' })
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    containerRegistryName: aiProject.outputs.dependentResources.registry.name
    identityName: containerAppsIdentity.outputs.name
    containerName: 'frontend'
    imageName: frontendImageName
    targetPort: 3000
    external: true
    ingressEnabled: true
    containerCpuCoreCount: '0.5'
    containerMemory: '1.0Gi'
    containerMinReplicas: 1
    containerMaxReplicas: 3
    env: [
      {
        name: 'BACKEND_API_URL'
        value: 'https://${abbrs.appContainerApps}backend-${resourceToken}.${containerAppsEnvironment.outputs.defaultDomain}'
      }
      {
        name: 'NODE_ENV'
        value: 'production'
      }
    ]
  }
}

// Backend Container App (internal - AI Agent service)
module backendContainerApp 'core/host/container-app.bicep' = if (enableContainerApps) {
  scope: rg
  name: 'backend-container-app'
  params: {
    name: '${abbrs.appContainerApps}backend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'backend' })
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    containerRegistryName: aiProject.outputs.dependentResources.registry.name
    identityName: containerAppsIdentity.outputs.name
    containerName: 'backend'
    imageName: backendImageName
    targetPort: 8000
    external: false
    ingressEnabled: true
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    containerMinReplicas: 1
    containerMaxReplicas: 5
    env: [
      {
        name: 'AZURE_AI_PROJECT_ENDPOINT'
        value: aiProject.outputs.AZURE_AI_PROJECT_ENDPOINT
      }
      {
        name: 'AZURE_OPENAI_ENDPOINT'
        value: aiProject.outputs.AZURE_OPENAI_ENDPOINT
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: aiProject.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
      }
      {
        name: 'MCP_SERVER_URL'
        value: 'https://${abbrs.appContainerApps}mcp-server-${resourceToken}.${containerAppsEnvironment.outputs.defaultDomain}'
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: containerAppsIdentity.outputs.clientId
      }
    ]
  }
}

// MCP Server Container App (internal - Weather tool server)
module mcpServerContainerApp 'core/host/container-app.bicep' = if (enableContainerApps) {
  scope: rg
  name: 'mcp-server-container-app'
  params: {
    name: '${abbrs.appContainerApps}mcp-server-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'mcp-server' })
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    containerRegistryName: aiProject.outputs.dependentResources.registry.name
    identityName: containerAppsIdentity.outputs.name
    containerName: 'mcp-server'
    imageName: mcpServerImageName
    targetPort: 8080
    external: false
    ingressEnabled: true
    containerCpuCoreCount: '0.5'
    containerMemory: '1.0Gi'
    containerMinReplicas: 1
    containerMaxReplicas: 3
    env: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: aiProject.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
      }
    ]
  }
}

// Resources
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_AI_ACCOUNT_ID string = aiProject.outputs.accountId
output AZURE_AI_PROJECT_ID string = aiProject.outputs.projectId
output AZURE_AI_FOUNDRY_PROJECT_ID string = aiProject.outputs.projectId
output AZURE_AI_ACCOUNT_NAME string = aiProject.outputs.aiServicesAccountName
output AZURE_AI_PROJECT_NAME string = aiProject.outputs.projectName

// Endpoints
output AZURE_AI_PROJECT_ENDPOINT string = aiProject.outputs.AZURE_AI_PROJECT_ENDPOINT
output AZURE_OPENAI_ENDPOINT string = aiProject.outputs.AZURE_OPENAI_ENDPOINT
output APPLICATIONINSIGHTS_CONNECTION_STRING string = aiProject.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING

// Dependent Resources and Connections

// ACR
output AZURE_AI_PROJECT_ACR_CONNECTION_NAME string = aiProject.outputs.dependentResources.registry.connectionName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = aiProject.outputs.dependentResources.registry.loginServer

// Bing Search
output BING_GROUNDING_CONNECTION_NAME  string = aiProject.outputs.dependentResources.bing_grounding.connectionName
output BING_GROUNDING_RESOURCE_NAME string = aiProject.outputs.dependentResources.bing_grounding.name
output BING_GROUNDING_CONNECTION_ID string = aiProject.outputs.dependentResources.bing_grounding.connectionId

// Bing Custom Search
output BING_CUSTOM_GROUNDING_CONNECTION_NAME string = aiProject.outputs.dependentResources.bing_custom_grounding.connectionName
output BING_CUSTOM_GROUNDING_NAME string = aiProject.outputs.dependentResources.bing_custom_grounding.name
output BING_CUSTOM_GROUNDING_CONNECTION_ID string = aiProject.outputs.dependentResources.bing_custom_grounding.connectionId

// Azure AI Search
output AZURE_AI_SEARCH_CONNECTION_NAME string = aiProject.outputs.dependentResources.search.connectionName
output AZURE_AI_SEARCH_SERVICE_NAME string = aiProject.outputs.dependentResources.search.serviceName

// Azure Storage
output AZURE_STORAGE_CONNECTION_NAME string = aiProject.outputs.dependentResources.storage.connectionName
output AZURE_STORAGE_ACCOUNT_NAME string = aiProject.outputs.dependentResources.storage.accountName

// Container Apps
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = enableContainerApps ? containerAppsEnvironment.outputs.name : ''
output AZURE_CONTAINER_APPS_ENVIRONMENT_DOMAIN string = enableContainerApps ? containerAppsEnvironment.outputs.defaultDomain : ''

// Frontend Container App
output FRONTEND_CONTAINER_APP_NAME string = enableContainerApps ? frontendContainerApp.outputs.name : ''
output FRONTEND_URI string = enableContainerApps ? frontendContainerApp.outputs.uri : ''

// Backend Container App
output BACKEND_CONTAINER_APP_NAME string = enableContainerApps ? backendContainerApp.outputs.name : ''
output BACKEND_URI string = enableContainerApps ? backendContainerApp.outputs.uri : ''

// MCP Server Container App
output MCP_SERVER_CONTAINER_APP_NAME string = enableContainerApps ? mcpServerContainerApp.outputs.name : ''
output MCP_SERVER_URI string = enableContainerApps ? mcpServerContainerApp.outputs.uri : ''

// User Assigned Identity
output AZURE_CONTAINER_APPS_IDENTITY_ID string = enableContainerApps ? containerAppsIdentity.outputs.id : ''
output AZURE_CONTAINER_APPS_IDENTITY_CLIENT_ID string = enableContainerApps ? containerAppsIdentity.outputs.clientId : ''
