Darkswarm.directive "shippingTypeSelector", ->
  restrict: 'E'
  templateUrl: 'shipping_type_selector.html'
  link: (scope, elem, attr)->
    scope.shippingTypes = 
      pickup: false
      delivery: false 
