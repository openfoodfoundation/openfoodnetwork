Darkswarm.directive "enterpriseModal", ($modal)->
  restrict: 'E'
  replace: true
  template: "<a ng-transclude></a>"
  transclude: true
  link: (scope, elem, attrs, ctrl)->
    elem.on "click", (ev)=>
      ev.stopPropagation()
      scope.modalInstance = $modal.open(controller: ctrl, templateUrl: 'enterprise_modal.html', scope: scope)
