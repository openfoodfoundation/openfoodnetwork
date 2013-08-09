'use strict'

angular.module('store', ['ngResource']).
  controller 'CartCtrl', ($scope, $window, CartFactory) ->

    $scope.loadCart = ->
      $scope.cart = CartFactory.load(1)

    $scope.addVariant = (variant, quantity) ->

  .config(['$httpProvider', ($httpProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
  ])





