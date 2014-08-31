Darkswarm.directive "ofnFlash", (flash, $timeout, RailsFlashLoader)->
  # Mappings between flash types (left) and Foundation classes
  typePairings =
    info: "info"
    error: "alert"
    success: "success"
  scope: {}
  restrict: 'E'
  templateUrl: "flash.html"
  controller: ($scope)->
    $scope.closeAlert = (index)->
      $scope.flashes.splice(index, 1)

  link: ($scope, element, attr) ->
    $scope.flashes = []
    show = (message, type)=>
      if message
        $scope.flashes.push({message: message, type: typePairings[type]})
        $timeout($scope.delete, 10000)

    $scope.delete = ->
      $scope.flashes.shift()

    flash.subscribe(show)
    RailsFlashLoader.initFlash()
