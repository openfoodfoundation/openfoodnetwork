angular.module("admin.enterprises")
  .controller "changeTypeFormCtrl", ($scope, enterprise) ->
    $scope.sells = enterprise.sells
    $scope.producer_profile_only = enterprise.producer_profile_only
    $scope.submitted = false

    $scope.valid = (form) ->
      $scope.submitted = !form.$valid
      form.$valid

    $scope.submit = (form) ->
      event.preventDefault() unless $scope.valid(form)
