resource storageGood 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'goodstorage'
  location: 'eastus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource storageBad 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'badstorage'
  location: 'eastus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: false
  }
}
