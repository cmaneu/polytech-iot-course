targetScope = 'subscription'

// If an environment is set up (dev, test, prod...), it is used in the application name
param applicationName string = 'iot-workshop'
param location string = 'westeurope'
var instanceNumber = '001'

var defaultTags = {
  'application': applicationName
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${applicationName}-${instanceNumber}'
  location: location
  tags: defaultTags
}


module iotHub 'modules/iot-hub.bicep' = {
  name: 'iotHub'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    resourceTags: defaultTags
    instanceNumber: instanceNumber
  }
}

