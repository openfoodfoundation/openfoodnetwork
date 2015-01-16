describe "permalinkCtrl", ->
  ctrl = null
  $scope = null
  Enterprise = null
  PermalinkChecker = null
  $httpBackend = null
  $q = null


  beforeEach ->
    module('admin.enterprises')
    Enterprise = {
      permalink: "something"
    }

    inject ($rootScope, $controller, _$q_, _PermalinkChecker_) ->
      $scope = $rootScope
      $q = _$q_
      PermalinkChecker = _PermalinkChecker_
      $ctrl = $controller 'permalinkCtrl', {$scope: $scope, Enterprise: Enterprise, PermalinkChecker: PermalinkChecker}

  describe "checking permalink", ->
    deferred = null
    beforeEach ->
      # Build a deferred object
      deferred = $q.defer()

    it "sends a request to PermalinkChecker when permalink is changed", ->
      deferred.resolve("")
      promise = deferred.promise
      spyOn(PermalinkChecker, "check").andReturn promise
      $scope.$apply Enterprise.permalink = "somethingelse" # Change the permalink
      expect(PermalinkChecker.check).toHaveBeenCalled()

    it "sets available to 'Available' when PermalinkChecker resolves", ->
      deferred.resolve("")
      promise = deferred.promise
      spyOn(PermalinkChecker, "check").andReturn promise
      $scope.$apply Enterprise.permalink = "somethingelse" # Change the permalink
      expect($scope.availability).toEqual "Available"

    it "sets available to 'Unavailable' when PermalinkChecker rejects", ->
      deferred.reject()
      promise = deferred.promise
      spyOn(PermalinkChecker, "check").andReturn promise
      $scope.$apply Enterprise.permalink = "somethingelse" # Change the permalink
      expect($scope.availability).toEqual "Unavailable"
