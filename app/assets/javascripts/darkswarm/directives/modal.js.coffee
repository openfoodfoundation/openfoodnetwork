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
      scope.modalInstance = $modal.open(controller: ctrl, template: contents)

# TODO THIS IS TERRIBLE PLEASE FIX NG-BIND-HTML
Darkswarm.directive "injectHtml", ->
  restrict: 'A'
  scope:
    injectHtml: "="
  link: (scope, elem, attrs, ctrl)->
    elem.html(scope.injectHtml)
