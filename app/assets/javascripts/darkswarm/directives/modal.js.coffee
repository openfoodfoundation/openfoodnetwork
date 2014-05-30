Darkswarm.directive "ofnModal", ($modal)->
  restrict: 'E'
  replace: true
  transclude: true
  scope: {}
  template: "<a>{{title}}</a>"

  link: (scope, elem, attrs, ctrl, transclude)->
    scope.title = attrs.title
    contents = null
    # We're using an isolate scope, which is a child of the original scope
    # We have to compile the transclude against the original scope, not the isolate
    transclude scope.$parent, (clone)->
      contents = clone

    elem.on "click", =>
      scope.modalInstance = $modal.open(controller: ctrl, template: contents, scope: scope.$parent)
