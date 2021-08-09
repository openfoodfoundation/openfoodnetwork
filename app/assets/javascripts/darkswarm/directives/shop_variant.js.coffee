angular.module('Darkswarm').directive "shopVariant", ->
  restrict: 'E'
  replace: true
  templateUrl: 'shop_variant.html'
  scope:
    variant: '='
  controller: 'ShopVariantCtrl'
