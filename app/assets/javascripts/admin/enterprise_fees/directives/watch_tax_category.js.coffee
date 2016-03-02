angular.module("admin.enterpriseFees").directive 'watchTaxCategory', ->
  # In order to have a nice user experience on this page, we're modelling tax_category
  # inheritance using tax_category_id = -1.
  # This directive acts as a parser for tax_category_id, storing the value the form as "" when
  # tax_category is to be inherited and setting inherits_tax_category as appropriate.
  (scope, element, attrs) ->
    scope.$watch 'enterprise_fee.tax_category_id', (value) ->
      if value == -1
        scope.enterprise_fee.inherits_tax_category = true
        element.val("")
      else
        scope.enterprise_fee.inherits_tax_category = false
        element.val(value)

    scope.enterprise_fee.tax_category_id = -1 if scope.enterprise_fee.inherits_tax_category
