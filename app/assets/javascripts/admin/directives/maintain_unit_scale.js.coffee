angular.module("ofn.admin").directive "ofnMaintainUnitScale", ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    scope.$watch 'product.variant_unit_with_scale', (newValue, oldValue) ->
      if not (oldValue == newValue)
        # Triggers track-variant directive to track the unit_value, so that changes to the unit are passed to the server
        ngModel.$setViewValue ngModel.$viewValue
        