describe "EnterpriseRegistrationService", ->
  EnterpriseRegistrationService = null
  availableCountries = []
  enterpriseAttributes =
    name: "Enterprise 1"
    something: true
  spreeApiKey = "keykeykeykey"
  CurrentUser =
    id: 2
    email: 'lalala@email.com'

  beforeEach ->
    module('Darkswarm')
    angular.module('Darkswarm').value 'availableCountries', availableCountries
    angular.module('Darkswarm').value 'enterpriseAttributes', enterpriseAttributes
    angular.module('Darkswarm').value 'spreeApiKey', spreeApiKey
    angular.module('Darkswarm').value 'CurrentUser', CurrentUser

    inject ($injector)->
      EnterpriseRegistrationService = $injector.get("EnterpriseRegistrationService")

  it "adds the specified attributes to the ERS enterprise object", ->
    expect(EnterpriseRegistrationService.enterprise.name).toBe "Enterprise 1"
    expect(EnterpriseRegistrationService.enterprise.something).toBe true