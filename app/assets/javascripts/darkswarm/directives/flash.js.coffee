Darkswarm.directive "ofnFlash", (flash, $timeout)->
  scope: {}
  restrict: 'AE'
  template: "<alert ng-repeat='flash in flashes' type='flash.type'>{{flash.message}}</alert>"
  link: ($scope, element, attr) ->
    $scope.flashes = []
    show = (message, type)->
      if message
        $scope.flashes.push({message: message, type: type})
        $timeout($scope.delete, 5000)

    $scope.delete = ->
      $scope.flashes.shift()

    flash.subscribe(show)
