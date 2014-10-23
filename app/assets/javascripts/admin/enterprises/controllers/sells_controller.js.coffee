angular.module("admin.enterprises")
  .controller "sellsCtrl", ($scope) ->
    $scope.sells = "unspecified"
    $scope.producer_profile_only = true
    $scope.submitted = false

    $scope.valid = (form) ->
      $scope.submitted = !form.$valid
      form.$valid

    $scope.submit = (form) ->
      event.preventDefault() unless $scope.valid(form)
