angular.module('Darkswarm').directive "ofnOnHand", (StockQuantity, Messages) ->
  restrict: 'A'
  require: "ngModel"
  scope: true

  link: (scope, elem, attr, ngModel) ->
    # In cases where this field gets its value from the HTML element rather than the model,
    # initialise the model with the HTML value.
    if scope.$eval(attr.ngModel) == undefined
      # Don't dirty the model when we do this
      setDirty = ngModel.$setDirty
      ngModel.$setDirty = angular.noop
      ngModel.$setViewValue(elem.val())
      ngModel.$setDirty = setDirty

    ngModel.$parsers.push (viewValue) ->
      available_quantity = scope.available_quantity()
      if parseInt(viewValue) > available_quantity
        Messages.flash({error: t("js.insufficient_stock", {on_hand: available_quantity})})
        viewValue = available_quantity
        ngModel.$setViewValue viewValue
        ngModel.$render()

      viewValue

    scope.available_quantity = ->
      StockQuantity.available_quantity(attr.ofnOnHand, attr.finalizedquantity)
