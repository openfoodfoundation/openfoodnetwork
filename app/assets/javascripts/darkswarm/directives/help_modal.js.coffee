angular.module('Darkswarm').directive "helpModal", ($modal, $compile, $templateCache)->
  restrict: 'A'
  scope:
    helpText: "@helpModal"

  link: (scope, elem, attrs, ctrl)->
    compiled = $compile($templateCache.get('help-modal.html'))(scope)

    elem.on "click", =>
      $modal.open(controller: ctrl, template: compiled, scope: scope, windowClass: 'help-modal small')

    scope.$on "$destroy", ->
      elem.off("click")
