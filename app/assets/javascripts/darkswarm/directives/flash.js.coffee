angular.module('Darkswarm').directive "ofnFlash", (flash, $timeout, RailsFlashLoader)->
  # Our own flash class. Uses the "flash" service (third party), and a directive 
  # called RailsFlashLoader to render
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
    
    # Callback when a new flash message is pushed to flash service
    show = (message, type)=>
      return unless message
      # if same message already exists, don't add it again
      return if $scope.flashes.some((flash) -> flash.message == message)

      $scope.flashes.push({message: message, type: typePairings[type]})
      $timeout($scope.delete, 10000)

    $scope.delete = ->
      $scope.flashes.shift()

    # Register our callback (above) with flash service
    flash.subscribe(show)
    RailsFlashLoader.initFlash()
