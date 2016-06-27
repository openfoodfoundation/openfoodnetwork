angular.module("admin.utils").directive "ofnSortable", ($timeout, $parse) ->
  restrict: "E"
  scope:
    items: '@'
    position: '@'
    afterSort: '&'
    handle: "@"
    axis: "@"
  link: (scope, element, attrs) ->
    $timeout ->
      scope.axis ||= "y"
      scope.handle ||= ".handle"
      getScopePos = $parse(scope.position)
      setScopePos = getScopePos.assign

      element.sortable
        handle: scope.handle
        helper: 'clone'
        axis: scope.axis
        items: scope.items
        appendTo: element
        update: (event, ui) ->
          scope.$apply ->
            sortableSiblings = ($(ss) for ss in ui.item.siblings(scope.items))
            offset = Math.min(ui.item.index(), sortableSiblings[0].index())
            newPos = ui.item.index() - offset + 1
            oldPos = getScopePos(ui.item.scope())
            if newPos < oldPos
              for sibScope in sortableSiblings.map((ss) -> ss.scope())
                pos = getScopePos(sibScope)
                setScopePos(sibScope, pos + 1) if pos >= newPos && pos < oldPos
            else if newPos > oldPos
              for sibScope in sortableSiblings.map((ss) -> ss.scope())
                pos = getScopePos(sibScope)
                setScopePos(sibScope, pos - 1) if pos > oldPos && pos <= newPos
            setScopePos(ui.item.scope(), newPos)
            scope.afterSort()
