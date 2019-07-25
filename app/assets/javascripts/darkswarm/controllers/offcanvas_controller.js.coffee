Darkswarm.controller "OffcanvasCtrl", ($scope, $window) ->
  $scope.menu = $(".left-off-canvas-menu")

  $scope.setOffcanvasMenuHeight = ->
    $scope.menu.height($(window).height())

  $scope.bind = ->
    $(window).on("resize", $scope.setOffcanvasMenuHeight)
    $scope.setOffcanvasMenuHeight()

  $scope.bind()
