@description('Name of the Azure Web App')
param siteName string = 'librechat-app'

@description('Name of the App Service Plan')
param hostingPlanName string = 'librechat-plan'

@description('The pricing tier for the hosting plan')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param sku string = 'B2'

@description('Name of the Cosmos DB account (MongoDB API)')
param cosmosDBAccountName string = 'librechat-cosmosdb'

@description('Name of the MongoDB database')
param cosmosDBDatabaseName string = 'LibreChat'

@description('Name of the storage account for file uploads')
param storageAccountName string = 'librechatsa${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('GitHub repository URL')
param repoUrl string = 'https://github.com/v-khdumi/LibreChat.git'

@description('GitHub branch to deploy')
param branch string = 'main'

// Variables
var cosmosDBConnectionString = 'mongodb://${cosmosDBAccountName}:${cosmosDB.listKeys().primaryMasterKey}@${cosmosDBAccountName}.mongo.cosmos.azure.com:10255/${cosmosDBDatabaseName}?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@${cosmosDBAccountName}@'

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=core.windows.net;AccountKey=${storageAccount.listKeys().keys[0].value}'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storageAccount
  name: 'default'
}

// Blob Container
resource uploadContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobService
  name: 'uploads'
  properties: {
    publicAccess: 'None'
  }
}

// Cosmos DB Account
resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: cosmosDBAccountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableMongo'
      }
    ]
    apiProperties: {
      serverVersion: '4.2'
    }
  }
}

// Cosmos DB Database
resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2021-04-15' = {
  parent: cosmosDB
  name: cosmosDBDatabaseName
  properties: {
    resource: {
      id: cosmosDBDatabaseName
    }
    options: {
      throughput: 400
    }
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: siteName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appCommandLine: 'bash startup.sh'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'MONGO_URI'
          value: cosmosDBConnectionString
        }
        {
          name: 'HOST'
          value: '0.0.0.0'
        }
        {
          name: 'PORT'
          value: '8080'
        }
        {
          name: 'DOMAIN_CLIENT'
          value: 'https://${siteName}.azurewebsites.net'
        }
        {
          name: 'DOMAIN_SERVER'
          value: 'https://${siteName}.azurewebsites.net'
        }
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: storageConnectionString
        }
        {
          name: 'AZURE_CONTAINER_NAME'
          value: 'uploads'
        }
        {
          name: 'FILE_STRATEGY'
          value: 'azure'
        }
        {
          name: 'CONSOLE_JSON'
          value: 'true'
        }
        {
          name: 'TRUST_PROXY'
          value: '1'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '20.11.1'
        }
      ]
    }
  }
}

// Source Control Configuration
resource sourceControl 'Microsoft.Web/sites/sourcecontrols@2021-02-01' = {
  parent: webApp
  name: 'web'
  properties: {
    repoUrl: repoUrl
    branch: branch
    isManualIntegration: true
  }
}

// Outputs
output webAppUrl string = 'https://${siteName}.azurewebsites.net'
output mongoConnectionString string = cosmosDBConnectionString