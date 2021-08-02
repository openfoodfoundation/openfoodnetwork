angular.module('Darkswarm').controller "DetailsCtrl", ($scope, $timeout, $http, CurrentUser, AuthenticationService, SpreeUser) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.name = "details"
  $scope.nextPanel = "billing"

  $scope.login_or_next = (event) ->
    event.preventDefault()
    unless CurrentUser.id
      $scope.ensureUserIsGuest($scope.next)
      return

    $scope.next()

  $scope.summary = ->
    [$scope.fullName(),
    $scope.order.email,
    $scope.order.bill_address.phone]

  $scope.fullName = ->
    [$scope.order.bill_address.firstname ? null,
    $scope.order.bill_address.lastname ? null].join(" ").trim()

  $timeout $scope.onTimeout
