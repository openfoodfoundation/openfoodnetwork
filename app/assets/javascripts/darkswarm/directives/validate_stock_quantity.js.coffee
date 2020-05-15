Darkswarm.directive "validateStockQuantity", ->
  restrict: 'A'
  require: "ngModel"

  link: (scope, element, attr, ngModel) ->
    ngModel.$parsers.push (selectedQuantity) ->
      if parseInt(selectedQuantity) > scope.available_quantity()
        ngModel.$setValidity('stock', false);
      else
        ngModel.$setValidity('stock', true);

      selectedQuantity

    scope.available_quantity = ->
      on_hand = parseInt(attr.ofnOnHand)
      finalized_quantity = parseInt(attr.finalizedquantity) || 0 # finalizedquantity is optional
      on_hand + finalized_quantity
