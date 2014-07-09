Darkswarm.directive "shippingTypeSelector", (FilterSelectorsService)->
  restrict: 'E'
  templateUrl: 'shipping_type_selector.html'
  link: (scope, elem, attr)->
    scope.shippingTypes =
      pickup: false
      delivery: false

    scope.selectors = 
      delivery: FilterSelectorsService.new()
      pickup: FilterSelectorsService.new()
      
    scope.emit = ->
      scope.shippingTypes =
        pickup: scope.selectors.pickup.active
        delivery: scope.selectors.delivery.active
