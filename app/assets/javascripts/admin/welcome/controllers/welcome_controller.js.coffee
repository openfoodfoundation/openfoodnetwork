angular.module("admin.welcome")
  .controller "welcomeCtrl", ($scope) ->
    $scope.sells = "unspecified"
    $scope.submitted = false

    $scope.valid = (form) ->
      $scope.submitted = !form.$valid
      form.$valid

    $scope.submit = (form) ->
      event.preventDefault() unless $scope.valid(form)
