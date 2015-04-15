angular.module("ofn.admin").directive "ofnLineItemUpdAttr", (switchClass, pendingChanges) ->
  scope:
    lineItem: "&ofnLineItemUpdAttr"
    attrName: "@"
  link: (scope, element, attrs) ->
    element.dbValue = scope.lineItem()[scope.attrName]
    scope.$watch "lineItem().#{scope.attrName}", (value) ->
      if value == element.dbValue
        pendingChanges.remove(scope.lineItem().id, scope.attrName)
        switchClass( element, "", ["update-pending", "update-error", "update-success"], false )
      else
        changeObj =
          lineItem: scope.lineItem()
          element: element
          attrName: scope.attrName
          url: "/api/orders/#{scope.lineItem().order.number}/line_items/#{scope.lineItem().id}?line_item[#{scope.attrName}]=#{value}"
        pendingChanges.add(scope.lineItem().id, scope.attrName, changeObj)
        switchClass( element, "update-pending", ["update-error", "update-success"], false )
