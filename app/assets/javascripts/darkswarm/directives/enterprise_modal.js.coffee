Darkswarm.directive "enterpriseModal", ($modal, Enterprises, EnterpriseResource) ->
  restrict: 'E'
  replace: true
  template: "<a ng-transclude></a>"
  transclude: true
  link: (scope, elem, attrs, ctrl) ->
    elem.on "click", (ev) =>
      ev.stopPropagation()
      params =
        id: scope.enterprise.id
      EnterpriseResource.relatives params, (data) =>
        Enterprises.addEnterprises data
        scope.enterprise = Enterprises.enterprises_by_id[scope.enterprise.id]
        Enterprises.dereferenceEnterprise scope.enterprise
      scope.modalInstance = $modal.open(controller: ctrl, templateUrl: 'enterprise_modal.html', scope: scope)
