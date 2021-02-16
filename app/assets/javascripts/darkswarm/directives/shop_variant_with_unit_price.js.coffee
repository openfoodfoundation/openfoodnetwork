Darkswarm.directive "shopVariantWithUnitPrice", ->
  restrict: 'E'
  replace: true
  templateUrl: 'shop_variant_with_unit_price.html'
  scope:
    variant: '='
  controller: 'ShopVariantCtrl'
