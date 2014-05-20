Darkswarm.directive "ofnModal", ($modal)->
  restrict: 'E'
  replace: true
  transclude: true
  scope: {}
  template: "<a>{{title}}</a>"

  link: (scope, elem, attrs, ctrl, transclude)->
    scope.title = attrs.title
    contents = null
    transclude scope, (clone)->
      contents = clone

    elem.on "click", =>
      scope.modalInstance = $modal.open(controller: ctrl, template: contents)
