angular.module("admin.enterprises")
  .controller "permalinkCtrl", ($scope, PermalinkChecker) ->
    # locals
    initialPermalink = $scope.Enterprise.permalink
    pendingRequest = null

    # variables on $scope
    $scope.availablility = ""
    $scope.checking = false

    $scope.$watch "Enterprise.permalink", (newValue, oldValue) ->
      $scope.checking = true
      pendingRequest = PermalinkChecker.check(newValue)

      pendingRequest.then (data) ->
        if data.permalink == initialPermalink
          $scope.availability = ""
        else
          $scope.availability = data.available
        $scope.Enterprise.permalink = data.permalink
        $scope.checking = false
      , (data) ->
        # Do nothing (this is hopefully an aborted request)
