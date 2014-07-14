Darkswarm.directive "shippingTypeSelector", (FilterSelectorsService)->
  restrict: 'E'
  replace: true
  templateUrl: 'shipping_type_selector.html'
  link: (scope, elem, attr)->
    scope.shippingTypes =
      pickup: false
      delivery: false

    scope.selectors = 
      delivery: FilterSelectorsService.new
        icon: "ofn-i_039-delivery"
      pickup: FilterSelectorsService.new
        icon: "ofn-i_038-takeaway"
      
    scope.emit = ->
      scope.shippingTypes =
        pickup: scope.selectors.pickup.active
        delivery: scope.selectors.delivery.active
