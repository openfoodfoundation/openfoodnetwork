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
        change =
          object: scope.object()
          type: scope.type
          attr: scope.attr
          value: if value? then value else ""
          scope: scope
        scope.pending()
        pendingChanges.add(scope.object().id, scope.attr, change)

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
