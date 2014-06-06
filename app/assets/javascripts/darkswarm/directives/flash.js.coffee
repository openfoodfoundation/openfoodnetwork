Darkswarm.directive "ofnFlash", (flash, $timeout)->
  typePairings =
    info: "standard"
    error: "alert"
    success: "success"
  scope: {}
  restrict: 'AE'
  templateUrl: "flash.html"
  controller: ($scope)->
    $scope.closeAlert = (index)->
      $scope.flashes.splice(index, 1)

  link: ($scope, element, attr) ->
    $scope.flashes = []
    show = (message, type)=>
      if message
        $scope.flashes.push({message: message, type: typePairings[type]})
        $timeout($scope.delete, 5000)

    $scope.delete = ->
      $scope.flashes.shift()

    flash.subscribe(show)
