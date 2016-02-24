# Used with the ngChange directive to prevent updates to the relevant model unless a callback returns true
angular.module("admin.lineItems").directive "confirmChange", ->
  restrict: "A"
  require: 'ngModel'
  scope:
    confirmChange: "&"
  link: (scope, element, attrs, ngModel) ->
    valid = null

    ngModel.$parsers.push (val) =>
      return val if val == valid
      if scope.confirmChange()
        # ngModel is changed, triggers ngChange callback
        return valid = val
      else
        valid = ngModel.$modelValue
        ngModel.$setViewValue(valid)
        ngModel.$render()
        return valid
