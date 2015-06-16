angular.module("admin.indexUtils").directive "panelRow", (Panels, Columns) ->
  restrict: "C"
  templateUrl: "admin/panel.html"
  scope:
    object: "="
    panels: "="
  link: (scope, element, attrs) ->
    scope.template = ""
    selected = null
    scope.columnCount = Columns.visibleCount

    scope.$on "columnCount:changed", (event, count) ->
      scope.columnCount = count

    setTemplate = ->
      if selected?
        scope.template = 'admin/panels/' + scope.panels[selected] + '.html'
      else
        scope.template = ""

    scope.getSelected = ->
      selected

    scope.setSelected = (name) ->
      scope.$apply ->
        selected = name
        setTemplate()

    scope.open = (name) ->
      element.show 0, ->
        scope.setSelected name

    scope.close = ->
      element.hide 0, ->
        scope.setSelected null

    Panels.register(scope.object.id, scope)
