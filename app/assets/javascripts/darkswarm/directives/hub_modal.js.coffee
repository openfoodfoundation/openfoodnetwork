Darkswarm.directive "hubModal", ($modal, $document)->
  restrict: 'E'
  replace: true
  template: "<a>{{enterprise.name}}</a>"
  link: (scope, elem, attrs, ctrl)->
    elem.on "click", (ev)=>
      ev.stopPropagation()
      scope.modalInstance = $modal.open(controller: ctrl, templateUrl: 'hub_modal.html', scope: scope)
      #$document.scrollTo 0, 0
      false
