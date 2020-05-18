Darkswarm.directive "validateStockQuantity", ->
  restrict: 'A'
  require: "ngModel"

  link: (scope, element, attr, ngModel) ->
    ngModel.$parsers.push (selectedQuantity) ->
      valid_number = parseInt(selectedQuantity) != NaN
      valid_quantity = parseInt(selectedQuantity) <= scope.available_quantity()

      ngModel.$setValidity('stock', (valid_number && valid_quantity) );

      selectedQuantity

    scope.available_quantity = ->
      on_hand = parseInt(attr.ofnOnHand)
      finalized_quantity = parseInt(attr.finalizedquantity) || 0 # finalizedquantity is optional
      on_hand + finalized_quantity
