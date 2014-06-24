Darkswarm.directive "hubModal", ($modal)->
  restrict: 'E'
  replace: true
  template: "<a>{{enterprise.name}}</a>"
  link: (scope, elem, attrs, ctrl)->
    elem.on "click", =>
      scope.modalInstance = $modal.open(controller: ctrl, templateUrl: 'hub_modal.html', scope: scope)
