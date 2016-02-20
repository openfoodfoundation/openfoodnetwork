Darkswarm.directive "shippingTypeSelector", ->
  # Builds selector for shipping types
  restrict: 'E'
  replace: true
  templateUrl: 'shipping_type_selector.html'
  link: (scope, elem, attr)->
    scope.shippingTypes =
      pickup: false
      delivery: false

    scope.selectors =
      delivery: scope.filterSelectors.new
        icon: "ofn-i_039-delivery"
      pickup: scope.filterSelectors.new
        icon: "ofn-i_038-takeaway"
      
    scope.emit = ->
      scope.shippingTypes =
        pickup: scope.selectors.pickup.active
        delivery: scope.selectors.delivery.active
