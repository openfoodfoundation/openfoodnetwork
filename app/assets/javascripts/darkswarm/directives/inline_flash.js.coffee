Darkswarm.directive "ofnInlineFlash", ->
  restrict: 'E'
  controller: ($scope) ->
    $scope.visible = true
    $scope.closeFlash = ->
      $scope.visible = false
