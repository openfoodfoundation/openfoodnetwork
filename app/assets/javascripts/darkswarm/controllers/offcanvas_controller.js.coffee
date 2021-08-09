angular.module('Darkswarm').controller "OffcanvasCtrl", ($scope) ->
  $scope.menu = $(".left-off-canvas-menu")

  $scope.setOffcanvasMenuHeight = ->
    $scope.menu.height($(window).height())

  $scope.bind = ->
    $(window).on("resize", $scope.setOffcanvasMenuHeight)
    $scope.setOffcanvasMenuHeight()

  $scope.bind()

  $scope.$on "$destroy", ->
    $(window).off("resize")
