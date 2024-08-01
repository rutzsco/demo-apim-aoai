param apimName string = ''

param payAsYouGoDeploymentOneBaseUrl string = 'https://rutzsco-aoai-06.openai.azure.com/'
param payAsYouGoDeploymentOneApiKey string = 'a9c276054c7e4dcb8c215a4e3cf2a8d3'
param payAsYouGoDeploymentTwoBaseUrl string = 'https://rutzsco-aoai-06.openai.azure.com/'
param payAsYouGoDeploymentTwoApiKey string = 'a9c276054c7e4dcb8c215a4e3cf2a8d3'


resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
}

resource payAsYouGoBackendOne 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'payg-backend-1'
  properties:{
    protocol: 'http'
    url: payAsYouGoDeploymentOneBaseUrl
    credentials: {
      header: {
        'api-key': [payAsYouGoDeploymentOneApiKey]
      }
    }
  }
}

resource payAsYouGoBackendTwo 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'payg-backend-2'
  properties:{
    protocol: 'http'
    url: payAsYouGoDeploymentTwoBaseUrl
    credentials: {
      header: {
        'api-key': [payAsYouGoDeploymentTwoApiKey]
      }
    }
  }
}

resource simpleRoundRobinBackendPool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  parent: apiManagementService
  name: 'simple-round-robin-backend-pool'
  properties:{
    type: 'Pool'
    pool: {
      services:[
        {
          id: payAsYouGoBackendOne.id
          weight: 1
          priority: 1
        }
        {
          id: payAsYouGoBackendTwo.id
          weight: 1
          priority: 1
        }
      ]
    }
  }
}

resource weightedRoundRobinBackendPool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  parent: apiManagementService
  name: 'weighted-round-robin-backend-pool'
  properties:{
    type: 'Pool'
    pool: {
      services:[
        {
          id: payAsYouGoBackendOne.id
          weight: 2
          priority: 1
        }
        {
          id: payAsYouGoBackendTwo.id
          weight: 1
          priority: 1
        }
      ]
    }
  }
}

resource retryWithPayAsYouGoBackendPool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  parent: apiManagementService
  name: 'retry-with-payg-backend-pool'
  properties:{
    type: 'Pool'
    pool: {
      services:[
        {
          id: payAsYouGoBackendOne.id
          weight: 1
          priority: 1
        }
        {
          id: payAsYouGoBackendOne.id
          weight: 1
          priority: 2
        }
      ]
    }
  }
}

// Fragments
resource simpleRoundRobinPolicyFragment 'Microsoft.ApiManagement/service/policyFragments@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'simple-round-robin-v2'
  properties: {
    value: loadTextContent('policy/simple-round-robin.xml')
    format: 'rawxml'
  }
  dependsOn: [payAsYouGoBackendOne, payAsYouGoBackendTwo]
}

resource weightedRoundRobinPolicyFragmentv2 'Microsoft.ApiManagement/service/policyFragments@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'weighted-round-robin-v2'
  properties: {
    value: loadTextContent('policy/weighted-round-robin.xml')
    format: 'rawxml'
  }
  dependsOn: [weightedRoundRobinBackendPool]
}

resource retryWithPayAsYouGoPolicyFragment 'Microsoft.ApiManagement/service/policyFragments@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'retry-with-payg-v2'
  properties: {
    value: loadTextContent('policy/retry-with-payg.xml')
    format: 'rawxml'
  }
  dependsOn: [payAsYouGoBackendOne, payAsYouGoBackendTwo]
}

// Policy

resource azureOpenAISimpleRoundRobinAPIPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: azureOpenAISimpleRoundRobinAPIv2
  name: 'policy'
  properties: {
    value: loadTextContent('policy/simple-round-robin-policy.xml')
    format: 'rawxml'
  }
  dependsOn: [simpleRoundRobinPolicyFragment]
}


resource azureOpenAIWeightedRoundRobinAPIPolicyv2 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: azureOpenAIWeightedRoundRobinAPIv2
  name: 'policy'
  properties: {
    value: loadTextContent('policy/weighted-round-robin-policy.xml')
    format: 'rawxml'
  }
  dependsOn: [weightedRoundRobinPolicyFragmentv2]
}

resource azureOpenAIRetryWithPayAsYouGoAPIPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: azureOpenAIRetryWithPayAsYouGoAPIv2
  name: 'policy'
  properties: {
    value: loadTextContent('policy/retry-with-payg-policy.xml')
    format: 'rawxml'
  }
  dependsOn: [retryWithPayAsYouGoPolicyFragment]
}

// APIS
resource azureOpenAIWeightedRoundRobinAPIv2 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'aoai-api-weighted-round-robin-v2'
  properties: {
    path: '/round-robin-weighted-v2/openai'
    displayName: 'AOAIAPI-WeightedRoundRobin-V2'
    protocols: ['https']
    value: loadTextContent('api-specs/openapi-spec.json')
    format: 'openapi+json'
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
}

resource azureOpenAISimpleRoundRobinAPIv2 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'aoai-api-simple-round-robin-v2'
  properties: {
    path: '/round-robin-simple-v2/openai'
    displayName: 'AOAIAPI-SimpleRoundRobin-V2'
    protocols: ['https']
    value: loadTextContent('api-specs/openapi-spec.json')
    format: 'openapi+json'
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
}

resource azureOpenAIRetryWithPayAsYouGoAPIv2 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagementService
  name: 'aoai-api-retry-with-payg-v2'
  properties: {
    path: '/retry-with-payg-v2/openai'
    displayName: 'AOAIAPI-RetryWithPayAsYouGo-V2'
    protocols: ['https']
    value: loadTextContent('api-specs/openapi-spec.json')
    format: 'openapi+json'
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
}
