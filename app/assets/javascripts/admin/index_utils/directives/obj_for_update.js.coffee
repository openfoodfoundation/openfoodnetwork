angular.module("admin.indexUtils").directive "objForUpdate", (switchClass, pendingChanges) ->
  scope:
    object: "&objForUpdate"
    type: "@objForUpdate"
    attr: "@attrForUpdate"
  link: (scope, element, attrs) ->
    scope.savedValue = scope.object()[scope.attr]

    scope.$watch "object().#{scope.attr}", (value) ->
      if value == scope.savedValue
        pendingChanges.remove(scope.object().id, scope.attr)
        scope.clear()
      else
        scope.pending()
        addPendingChange(scope.attr, value ? "")

    scope.reset = (value) ->
      scope.savedValue = value

    scope.success = ->
      switchClass( element, "update-success", ["update-pending", "update-error"], 5000 )

    scope.pending = ->
      switchClass( element, "update-pending", ["update-error", "update-success"], false )

    scope.error = ->
      switchClass( element, "update-error", ["update-pending", "update-success"], false )

    scope.clear = ->
      switchClass( element, "", ["update-pending", "update-error", "update-success"], false )

    # When a list of customer is filtered and we removed the "filtered value" from a customer, we
    # want to make sure the customer is updated. IE. filtering by tag, and removing said tag.
    # Deleting the "filtered value" from a customer will remove the customer entry, thus
    # removing "objForUpdate" directive from the active scope. That means $watch won't pick up
    # the attribute changed.
    # To ensure the customer is still updated, we check on the $destroy event to see if
    # the attribute has changed, if so we queue up the change.
    scope.$on '$destroy', (value) ->
      # No update
      return if scope.object()[scope.attr] is scope.savedValue

      # For some reason the code attribute is removed from the object when cleared, so we add
      # an emptyvalue so it gets updated properly
      if scope.attr is "code" and scope.object()[scope.attr] is undefined
        scope.object()["code"] = ""

      # Queuing up change
      addPendingChange(scope.attr, scope.object()[scope.attr])

    # private

    addPendingChange = (attr, value) ->
      change =
        object: scope.object()
        type: scope.type
        attr: attr
        value: value
        scope: scope
      pendingChanges.add(scope.object().id, attr, change)
