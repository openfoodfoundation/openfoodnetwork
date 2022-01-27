angular.module('Darkswarm').directive "shippingTypeSelector", ->
  # Builds selector for shipping types
  restrict: 'C'
  link: (scope, elem, attr)->
    scope.shippingTypes =
      pickup: false
      delivery: false

    scope.selectors =
      delivery: scope.filterSelectors.new
        icon: "ofn-i_039-delivery"
        translation_key: "hubs_delivery"
      pickup: scope.filterSelectors.new
        icon: "ofn-i_038-takeaway"
        translation_key: "hubs_pickup"
      
    scope.emit = ->
      scope.shippingTypes =
        pickup: scope.selectors.pickup.active
        delivery: scope.selectors.delivery.active
