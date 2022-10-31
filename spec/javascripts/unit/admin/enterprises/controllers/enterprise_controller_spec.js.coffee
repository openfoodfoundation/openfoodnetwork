describe "enterpriseCtrl", ->
  ctrl = null
  scope = null
  enterprise = null
  PaymentMethods = null
  Enterprises = null
  StatusMessage = null

  beforeEach ->
    module('admin.enterprises')
    enterprise =
      is_primary_producer: true
      sells: "none"
      owner:
        id: 98
    receivesNotifications = 99

    inject ($rootScope, $controller, _Enterprises_, _StatusMessage_) ->
      scope = $rootScope
      Enterprises = _Enterprises_
      StatusMessage = _StatusMessage_
      ctrl = $controller "enterpriseCtrl", {$scope: scope, enterprise: enterprise, EnterprisePaymentMethods: PaymentMethods, Enterprises: Enterprises, StatusMessage: StatusMessage, receivesNotifications: receivesNotifications}

  describe "initialisation", ->
    it "stores enterprise", ->
      expect(scope.Enterprise).toEqual enterprise

  describe "adding managers", ->
    u1 = u2 = u3 = null
    beforeEach ->
      u1 = { id: 1, email: 'name1@email.com', confirmed: true }
      u2 = { id: 2, email: 'name2@email.com', confirmed: true }
      u3 = { id: 3, email: 'name3@email.com', confirmed: true }
      enterprise.users = [u1, u2 ,u3]

    it "adds a user to the list", ->
      u4 = { id: 4, email: "name4@email.com", confirmed: true }
      scope.addManager u4
      expect(enterprise.users).toContain u4

    it "ignores object without an id", ->
      u4 = { not_id: 4, email: "name4@email.com", confirmed: true }
      scope.addManager u4
      expect(enterprise.users).not.toContain u4

    it "it ignores objects without an email", ->
      u4 = { id: 4, not_email: "name4@email.com", confirmed: true }
      scope.addManager u4
      expect(enterprise.users).not.toContain u4

    it "ignores objects that are already in the list, and alerts the user", ->
      spyOn(window, "alert").and.callThrough()
      u4 = { id: 3, email: "email-doesn't-matter.com", confirmed: true }
      scope.addManager u4
      expect(enterprise.users).not.toContain u4
      expect(window.alert).toHaveBeenCalledWith "email-doesn't-matter.com is already a manager!"


  describe "removing managers", ->
    u1 = u2 = u3 = null
    beforeEach ->
      u1 = { id: 1, email: 'name1@email.com', confirmed: true }
      u2 = { id: 2, email: 'name2@email.com', confirmed: true }
      u3 = { id: 3, email: 'name3@email.com', confirmed: true }
      enterprise.users = [u1, u2 ,u3]


    it "removes a user with the given id", ->
      scope.removeManager {id: 2}
      expect(enterprise.users).not.toContain u2

    it "does nothing when given object has no id attribute", ->
      scope.removeManager {not_id: 2}
      expect(enterprise.users).toEqual [u1,u2,u3]
