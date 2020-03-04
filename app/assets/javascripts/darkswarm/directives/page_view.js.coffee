Darkswarm.directive "pageView", ->
  restrict: "C"
  require: "^^pagesetCtrl"
  template: "<div ng-include='template'></div>"
  scope:
    templates: "="
  link: (scope, element, attrs, ctrl) ->
    scope.template = null

    ctrl.registerSelectionListener (prefix, selection) ->
      scope.template = "#{prefix}/#{selection}.html"
