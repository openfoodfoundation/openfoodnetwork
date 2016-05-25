describe "permalinkCtrl", ->
  ctrl = null
  $scope = null
  Enterprise = null
  PermalinkChecker = null
  $httpBackend = null
  $q = null


  beforeEach ->
    module('admin.enterprises')
    Enterprise =
      permalink: "something"

    inject ($rootScope, $controller, _$q_, _PermalinkChecker_) ->
      $scope = $rootScope
      $scope.Enterprise = Enterprise
      $q = _$q_
      PermalinkChecker = _PermalinkChecker_
      $ctrl = $controller 'permalinkCtrl', {$scope: $scope, PermalinkChecker: PermalinkChecker}

  describe "checking permalink", ->
    deferred = null
    beforeEach ->
      # Build a deferred object
      deferred = $q.defer()

    it "sends a request to PermalinkChecker when permalink is changed", ->
      deferred.resolve("")
      promise = deferred.promise
      spyOn(PermalinkChecker, "check").and.returnValue promise
      $scope.$apply Enterprise.permalink = "somethingelse" # Change the permalink
      expect(PermalinkChecker.check).toHaveBeenCalled()

    it "sets available to '' when PermalinkChecker resolves permalink to the existing permalink on Enterprise ", ->
      deferred.resolve({permalink: "something"})
      promise = deferred.promise
      spyOn(PermalinkChecker, "check").and.returnValue promise
      $scope.$apply Enterprise.permalink = "somethingelse" # Change the permalink
      expect($scope.availability).toEqual ""

    it "sets available and permalink when PermalinkChecker resolves", ->
      deferred.resolve({ available: "Available", permalink: "permalink"})
      promise = deferred.promise
      spyOn(PermalinkChecker, "check").and.returnValue promise
      $scope.$apply Enterprise.permalink = "somethingelse" # Change the permalink
      expect(Enterprise.permalink).toEqual "permalink"
      expect($scope.availability).toEqual "Available"

    it "does nothing when PermalinkChecker rejects", ->
      $scope.availability = "Some Availability"
      deferred.reject()
      promise = deferred.promise
      spyOn(PermalinkChecker, "check").and.returnValue promise
      $scope.$apply Enterprise.permalink = "somethingelse" # Change the permalink
      expect($scope.availability).toEqual "Some Availability"
      expect(Enterprise.permalink).toEqual "somethingelse"
