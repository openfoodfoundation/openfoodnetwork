angular.module('Darkswarm').controller "HomeCtrl", ($scope) ->
  $scope.brandStoryExpanded = false

  $scope.toggleBrandStory = ->
    $scope.brandStoryExpanded = !$scope.brandStoryExpanded
