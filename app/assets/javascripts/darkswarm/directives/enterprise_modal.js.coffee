angular.module('Darkswarm').directive "enterpriseModal", (EnterpriseModal) ->
  restrict: 'E'
  replace: true
  template: "<a ng-transclude></a>"
  transclude: true
  link: (scope, elem, attrs, ctrl) ->
    elem.on "click", (event) =>
      event.stopPropagation()
      scope.modalInstance = EnterpriseModal.open scope.enterprise

    scope.$on "$destroy", ->
      elem.off("click")
