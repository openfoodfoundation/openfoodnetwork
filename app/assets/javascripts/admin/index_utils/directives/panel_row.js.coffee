angular.module("admin.indexUtils").directive "panelRow", (Panels, Columns) ->
  restrict: "C"
  require: "^^panelCtrl"
  templateUrl: "admin/panel.html"
  scope:
    object: "="
    panels: "="
    colspan: "=?"
    locals: '@?'
  link: (scope, element, attrs, ctrl) ->
    scope.template = null
    scope.columnCount = (scope.colspan || Columns.visibleCount)

    if scope.locals
      scope[local] = scope.$parent.$eval(local.trim()) for local in scope.locals.split(',')

    scope.$on "columnCount:changed", (event, count) ->
      scope.columnCount = count

    ctrl.registerSelectionListener (selection) ->
      if selection?
        scope.template = "admin/panels/#{scope.panels[selection]}.html"
      else
        scope.template = null
