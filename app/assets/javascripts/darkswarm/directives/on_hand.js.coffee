Darkswarm.directive "ofnOnHand", ->
  restrict: 'A'
  link: (scope, elem, attr) ->
    on_hand = parseInt(attr.ofnOnHand)
    elem.bind 'change', (e) ->
      if parseInt(elem.val()) > on_hand
        scope.$apply ->
          alert t('insufficient_stock', {on_hand: on_hand})
          elem.val(on_hand)
