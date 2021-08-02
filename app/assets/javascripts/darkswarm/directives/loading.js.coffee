angular.module('Darkswarm').directive "loading", (Loading)->
  # Triggers a screen-wide "loading" thing when Ajaxy stuff is happening
  scope: {}
  restrict: 'E'
  templateUrl: 'loading.html'
  controller: ($scope)->
    $scope.Loading = Loading
    $scope.show = ->
      $scope.Loading.message?
