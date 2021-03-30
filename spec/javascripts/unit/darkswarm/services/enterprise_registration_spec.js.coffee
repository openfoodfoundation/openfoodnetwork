describe "EnterpriseRegistrationService", ->
  EnterpriseRegistrationService = null
  $httpBackend = null
  availableCountries = []
  enterpriseAttributes =
    name: "Enterprise 1"
    something: true
  spreeApiKey = "keykeykeykey"
  CurrentUser =
    id: 2
    email: 'lalala@email.com'
  RegistrationServiceMock =
    select: -> null

  beforeEach ->
    module('Darkswarm')
    angular.module('Darkswarm').value 'availableCountries', availableCountries
    angular.module('Darkswarm').value 'enterpriseAttributes', enterpriseAttributes
    angular.module('Darkswarm').value 'spreeApiKey', spreeApiKey
    angular.module('Darkswarm').value 'CurrentUser', CurrentUser
    angular.module('Darkswarm').value 'RegistrationService', RegistrationServiceMock

    inject ($injector, _$httpBackend_) ->
      $httpBackend = _$httpBackend_
      EnterpriseRegistrationService = $injector.get("EnterpriseRegistrationService")

  it "adds the specified attributes to the ERS enterprise object", ->
    expect(EnterpriseRegistrationService.enterprise.name).toBe "Enterprise 1"
    expect(EnterpriseRegistrationService.enterprise.something).toBe true

  describe "creating an enterprise", ->
    describe "success", ->
      beforeEach ->
        spyOn(RegistrationServiceMock, "select")
        $httpBackend.expectPOST("/api/v0/enterprises?token=keykeykeykey").respond 200, 6
        EnterpriseRegistrationService.create()
        $httpBackend.flush()

      it "stores the id of the created enterprise", ->
        expect(EnterpriseRegistrationService.enterprise.id).toBe 6

      it "moves the user to the about page", ->
        expect(RegistrationServiceMock.select).toHaveBeenCalledWith 'about'

    describe "failure", ->
      beforeEach ->
        spyOn(RegistrationServiceMock, "select")
        spyOn(window, "alert")
        $httpBackend.expectPOST("/api/v0/enterprises?token=keykeykeykey").respond 400, 6
        EnterpriseRegistrationService.create()
        $httpBackend.flush()

      it "alerts the user to failure", ->
        expect(window.alert).toHaveBeenCalledWith 'Failed to create your enterprise.\nPlease ensure all fields are completely filled out.'

      it "does not move the user to the about page", ->
        expect(RegistrationServiceMock.select).not.toHaveBeenCalled

    describe "failure due to duplicate name", ->
      beforeEach ->
        spyOn(RegistrationServiceMock, "select")
        spyOn(window, "alert")
        $httpBackend.expectPOST("/api/v0/enterprises?token=keykeykeykey").respond 400, {"error": "Invalid resource. Please fix errors and try again.", "errors": {"name": ["has already been taken. If this is your enterprise and you would like to claim ownership, please contact the current manager of this profile at owner@example.com."], "permalink": [] }}
        EnterpriseRegistrationService.create()
        $httpBackend.flush()

      it "alerts the user to failure", ->
        expect(window.alert).toHaveBeenCalledWith 'Failed to create your enterprise.\nName has already been taken. If this is your enterprise and you would like to claim ownership, please contact the current manager of this profile at owner@example.com.'

      it "does not move the user to the about page", ->
        expect(RegistrationServiceMock.select).not.toHaveBeenCalled


  describe "updating an enterprise", ->
    beforeEach ->
      EnterpriseRegistrationService.enterprise.id = 78
      spyOn(RegistrationServiceMock, "select")

    describe "success", ->
      beforeEach ->
        $httpBackend.expectPUT("/api/v0/enterprises/78?token=keykeykeykey").respond 200, 6
        EnterpriseRegistrationService.update('step')
        $httpBackend.flush()

      it "moves the user to the about page", ->
        expect(RegistrationServiceMock.select).toHaveBeenCalledWith 'step'

    describe "failure", ->
      beforeEach ->
        spyOn(window, "alert")
        $httpBackend.expectPUT("/api/v0/enterprises/78?token=keykeykeykey").respond 400, 6
        EnterpriseRegistrationService.update('step')
        $httpBackend.flush()

      it "alerts the user to failure", ->
        expect(window.alert).toHaveBeenCalledWith 'Failed to update your enterprise.\nPlease ensure all fields are completely filled out.'

      it "does not move the user to the about page", ->
        expect(RegistrationServiceMock.select).not.toHaveBeenCalled
