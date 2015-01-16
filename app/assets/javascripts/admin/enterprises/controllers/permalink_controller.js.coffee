angular.module("admin.enterprises")
  .controller "permalinkCtrl", ($scope, PermalinkChecker) ->
    $scope.pristinePermalink = $scope.Enterprise.permalink
    $scope.availablility = ""
    $scope.checking = false

    $scope.$watch "Enterprise.permalink", (newValue, oldValue) ->
      if newValue == $scope.pristinePermalink
        $scope.availability = ""
      else
        $scope.checking = true
        PermalinkChecker.check(newValue).then (data) ->
          $scope.availability = 'Available'
          $scope.checking = false
        , (data) ->
          $scope.availability = 'Unavailable'
          $scope.checking = false