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
        value = if value? then value else ""
        addPendingChange(scope.attr, value)

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

    # In the particular case of a list of customer filtered by a tag, we want to make sure the
    # tag is removed when deleting the tag the list is filtered by.
    # As the list is filter by tag, deleting the tag will remove the customer entry, thus
    # removing "objForUpdate" directive from the active scope. That means $watch won't pick up
    # the tag_list changed.
    # To ensure the tag is still deleted, we check on the $destroy event to see if the tag_list has
    # changed, if so we queue up deleting the tag.
    scope.$on '$destroy', (value) ->
      return if scope.attr != 'tag_list'

      # No tag has been deleted
      return if scope.object()['tag_list'] == scope.savedValue

      # Queuing up change to delete tag
      addPendingChange('tag_list', scope.object()['tag_list'])

    # private

    addPendingChange = (attr, value) ->
      change =
        object: scope.object()
        type: scope.type
        attr: attr
        value: value
        scope: scope
      pendingChanges.add(scope.object().id, attr, change)
