Darkswarm.directive "ofnOnHand", ->
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
        alert t("js.insufficient_stock", {on_hand: available_quantity})
        viewValue = available_quantity
        ngModel.$setViewValue viewValue
        ngModel.$render()

      viewValue

    scope.available_quantity = ->
      on_hand = parseInt(attr.ofnOnHand)
      finalized_quantity = parseInt(attr.finalizedquantity) || 0 # finalizedquantity is optional
      on_hand + finalized_quantity
