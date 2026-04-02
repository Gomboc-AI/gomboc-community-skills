resource kvGood 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'goodvault'
  location: 'eastus'
  properties: {
    tenantId: 'aaaabbbb-cccc-dddd-eeee-ffffgggghhhh'
    enablePurgeProtection: true
    enableSoftDelete: true
  }
}

resource kvBadExplicit 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'badvault-explicit'
  location: 'eastus'
  properties: {
    tenantId: 'aaaabbbb-cccc-dddd-eeee-ffffgggghhhh'
    enablePurgeProtection: true
    enableSoftDelete: true
  }
}

resource kvBadMissing 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'badvault-missing'
  location: 'eastus'
  properties: {
    enablePurgeProtection: true
    tenantId: 'aaaabbbb-cccc-dddd-eeee-ffffgggghhhh'
    enableSoftDelete: true
  }
}
