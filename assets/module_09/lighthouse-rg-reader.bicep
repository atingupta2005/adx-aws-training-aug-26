@description('Display name of the Lighthouse offer')
param mspOfferName string

@description('Description shown when accepting / reviewing the offer')
param mspOfferDescription string

@description('Entra tenant ID of the managing (MSP / partner) tenant')
param managedByTenantId string

@description('Object ID of the user, group, or service principal in the managing tenant')
param principalId string

@description('Friendly name for the principal (e.g. security group display name)')
param principalIdDisplayName string

@description('Built-in Azure RBAC role definition ID (default = Reader)')
param roleDefinitionId string = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

// Registration definition + assignment at the resource group scope of this deployment.
// Deploy with: az deployment group create -g rg-lighthouse-demo -f lighthouse-rg-reader.bicep ...

var mspRegistrationName = guid(mspOfferName, managedByTenantId, principalId, resourceGroup().id)
var mspAssignmentName = guid(mspRegistrationName, resourceGroup().id)

resource mspRegistration 'Microsoft.ManagedServices/registrationDefinitions@2022-10-01' = {
  name: mspRegistrationName
  properties: {
    registrationDefinitionName: mspOfferName
    description: mspOfferDescription
    managedByTenantId: managedByTenantId
    authorizations: [
      {
        principalId: principalId
        principalIdDisplayName: principalIdDisplayName
        roleDefinitionId: roleDefinitionId
      }
    ]
  }
}

resource mspAssignment 'Microsoft.ManagedServices/registrationAssignments@2022-10-01' = {
  name: mspAssignmentName
  properties: {
    registrationDefinitionId: mspRegistration.id
  }
}

output registrationDefinitionId string = mspRegistration.id
output registrationAssignmentId string = mspAssignment.id
output delegatedResourceGroup string = resourceGroup().name
