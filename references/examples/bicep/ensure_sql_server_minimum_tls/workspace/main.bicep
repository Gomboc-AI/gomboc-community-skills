resource sqlServerGood 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: 'goodserver'
  location: 'eastus'
  properties: {
    administratorLogin: 'sqladmin'
    minimalTlsVersion: '1.2'
  }
}

resource sqlServerBadTls10 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: 'badserver-tls10'
  location: 'eastus'
  properties: {
    administratorLogin: 'sqladmin'
    minimalTlsVersion: '1.0'
  }
}

resource sqlServerBadTls11 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: 'badserver-tls11'
  location: 'eastus'
  properties: {
    administratorLogin: 'sqladmin'
    minimalTlsVersion: '1.1'
  }
}
