angular.module("ofn.admin").directive "ofnLineItemUpdAttr", [
  "switchClass", "pendingChanges"
  (switchClass, pendingChanges) ->
    require: "ngModel"
    link: (scope, element, attrs, ngModel) ->
      attrName = attrs.ofnLineItemUpdAttr
      element.dbValue = scope.$eval(attrs.ngModel)
      scope.$watch ->
        scope.$eval(attrs.ngModel)
      , (value) ->
        #if ngModel.$dirty
        #  i think i can take this out, this directive is still only called
        #  on a change and only an updated value will create a db call.
          if value == element.dbValue
            pendingChanges.remove(scope.line_item.id, attrName)
            switchClass( element, "", ["update-pending", "update-error", "update-success"], false )
          else
            changeObj =
              lineItem: scope.line_item
              element: element
              attrName: attrName
              url: "/api/orders/#{scope.line_item.order.number}/line_items/#{scope.line_item.id}?line_item[#{attrName}]=#{value}"
            pendingChanges.add(scope.line_item.id, attrName, changeObj)
            switchClass( element, "update-pending", ["update-error", "update-success"], false )
]
