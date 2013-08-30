'use strict'

angular.module('store', ['ngResource']).
  controller('CartCtrl', ['$scope', '$window', 'CartFactory', ($scope, $window, CartFactory) ->

    $scope.state = 'Empty'

    $scope.loadCart = (cart_id) ->
      if cart_id?
        CartFactory.load cart_id, (cart) ->
          $scope.cart = cart
          if $scope.cart?.orders?.length > 0
            $scope.state = "There's something there...."

    $scope.addVariant = (variant, quantity) ->

  ])
  .config(['$httpProvider', ($httpProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
  ])
