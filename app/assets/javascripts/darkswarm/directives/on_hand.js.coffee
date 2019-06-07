Darkswarm.directive "ofnOnHand", ->
  restrict: 'A'
  require: "ngModel"

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
      on_hand = parseInt(attr.ofnOnHand)
      finalized_quantity = parseInt(attr.finalizedquantity)
      available_quantity = on_hand + finalized_quantity
      if parseInt(viewValue) > available_quantity
        alert t("js.insufficient_stock", {on_hand: available_quantity})
        viewValue = available_quantity
        ngModel.$setViewValue viewValue
        ngModel.$render()

      viewValue
