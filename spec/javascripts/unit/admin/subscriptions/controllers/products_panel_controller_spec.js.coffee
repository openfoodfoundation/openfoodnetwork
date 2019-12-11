describe "ProductsPanelController", ->
  scope = null
  StatusMessage = null
  subscription = { shop_id: 1 }

  beforeEach ->
    module('admin.subscriptions')
    inject ($controller, $rootScope, _StatusMessage_) ->
      scope = $rootScope
      scope.object =  subscription
      StatusMessage = _StatusMessage_
      $controller 'ProductsPanelController', {$scope: scope, StatusMessage: _StatusMessage_}

  describe "saving subscription", ->
    update_promise_resolve = null
    update_promise_reject = null
    update_promise = null

    beforeEach ->
      update_promise = new Promise (resolve, reject) ->
        update_promise_resolve = resolve
        update_promise_reject = reject
      subscription.update = jasmine.createSpy('update').and.returnValue(update_promise)
      StatusMessage.display = jasmine.createSpy('display')

    it "updates subscription and updates status message while in progress and on success", ->
      scope.save()

      expect(subscription.update).toHaveBeenCalled()
      expect(StatusMessage.display).toHaveBeenCalledWith('progress', 'Saving...')
      expect(scope.saving).toEqual(true)

      update_promise.then ->
        expect(StatusMessage.display.calls.all()[1].args).toEqual(['success', 'Changes saved.'])
        expect(scope.saving).toEqual(false)
      update_promise_resolve()

    it "updates status message on errors", ->
      scope.save()

      update_promise.catch ->
        expect(StatusMessage.display.calls.all()[1].args).toEqual(['failure', 'Error saving subscription'])
        expect(scope.saving).toEqual(false)
      update_promise_reject("error")
