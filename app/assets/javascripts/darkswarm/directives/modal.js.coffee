angular.module('Darkswarm').directive "ofnModal", ($modal)->
  # Generic modal! Uses transclusion so designer-types can do stuff like:
  # %ofn-modal 
  #   CONTENT
  # Only works for simple cases, so roll your own when necessary!
  restrict: 'E'
  replace: true
  transclude: true
  scope: true
  template: "<a>{{title}}</a>"

  # Instead of using ng-transclude we compile the transcluded template to a string
  # This compiled template is sent to the $modal service! Such magic!
  # In theory we could compile the template directly inside link rather than onclick, but it's performant so meh!
  link: (scope, elem, attrs, ctrl, transclude)->
    scope.title = attrs.title
    elem.on "click", =>
      transclude scope, (clone)->
        scope.modalInstance = $modal.open(controller: ctrl, template: clone, scope: scope)

    scope.$on "$destroy", ->
      elem.off("click")
