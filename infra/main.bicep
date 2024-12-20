@description('The Azure location to create the resources in')
param location string = 'westeurope'

@description('Name for the service plan and web app (defines the subdomain)')
@minLength(3) // Ensures at least 3 characters
@maxLength(64) // Ensures no more than 64 characters
// NOTE: The appName must follow Azure naming rules: alphanumeric or hyphen only, cannot start/end with hyphen.
param appName string

@description('The container image to deploy')
param containerImage string

@description('The actor (GitHub username) that started the deployment')
param actor string

@description('The repository that started the deployment')
param repository string

targetScope = 'subscription'

// Resource group definition
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${appName}-rg'
  location: location
  tags: {
    actor: actor
    purpose: 'GitHub Actions workshop'
    repository: repository
  }
}

// Web app deployment module
module webApp 'web-app.bicep' = {
  name: 'web-app'
  scope: resourceGroup
  params: {
    appName: appName
    containerImage: containerImage
    location: location
    actor: actor
    repository: repository
  }
}

// Output the web app URL
output url string = 'https://${appName}.azurewebsites.net'
