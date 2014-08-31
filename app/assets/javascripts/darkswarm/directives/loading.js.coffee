Darkswarm.directive "loading", (Loading)->
  scope: {}
  restrict: 'E'
  templateUrl: 'loading.html'
  controller: ($scope)->
    $scope.Loading = Loading
    $scope.show = ->
      $scope.Loading.message?

  link: ($scope, element, attr)->
