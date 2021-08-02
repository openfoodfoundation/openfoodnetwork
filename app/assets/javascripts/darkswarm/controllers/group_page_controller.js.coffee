angular.module('Darkswarm').controller "GroupPageCtrl", ($scope, enterprises, Enterprises) ->
  $scope.Enterprises = Enterprises
  $scope.embedded_layout = window.location.search.indexOf("embedded_shopfront=true") != -1
