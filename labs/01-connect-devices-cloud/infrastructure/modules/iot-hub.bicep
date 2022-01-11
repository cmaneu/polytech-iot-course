param location string
param applicationName string
param resourceTags object
param instanceNumber string

resource symbolicname 'Microsoft.Devices/IotHubs@2021-07-02' = {
  name: 'hub-${applicationName}'
  location: location
  tags: resourceTags
  sku: {
    capacity: 1
    name: 'F1'
  }
}
