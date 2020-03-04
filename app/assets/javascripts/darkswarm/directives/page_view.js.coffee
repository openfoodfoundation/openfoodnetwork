Darkswarm.directive "pageView", ->
  restrict: "C"
  require: "^^pagesetCtrl"
  template: "<div ng-include='template'></div>"
  scope:
    templates: "="
  link: (scope, element, attrs, ctrl) ->
    scope.template = null

    ctrl.registerSelectionListener (prefix, selection) ->
      if selection?
        selection = "#{prefix}/#{selection}" if prefix?
        scope.template = "#{selection}.html"
      else
        scope.template = null
