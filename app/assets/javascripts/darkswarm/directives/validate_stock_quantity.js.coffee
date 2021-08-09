angular.module('Darkswarm').directive "validateStockQuantity", (StockQuantity) ->
  restrict: 'A'
  require: "ngModel"
  scope: true

  link: (scope, element, attr, ngModel) ->
    ngModel.$parsers.push (selectedQuantity) ->
      valid_number = parseInt(selectedQuantity) != NaN
      valid_quantity = parseInt(selectedQuantity) <= scope.available_quantity()

      ngModel.$setValidity('stock', (valid_number && valid_quantity) );

      selectedQuantity

    scope.available_quantity = ->
      StockQuantity.available_quantity(attr.ofnOnHand, attr.finalizedquantity)
