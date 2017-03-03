angular.module("ofn.admin").controller "FeedbackPanelsCtrl", ($scope) ->
  $scope.active = false

  $scope.togglePanel = ->
    $scope.active = !$scope.active
