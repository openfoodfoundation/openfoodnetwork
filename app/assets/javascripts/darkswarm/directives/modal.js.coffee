Darkswarm.directive "ofnModal", ($modal)->
  restrict: 'E'
  replace: true
  transclude: true
  template: "<a>{{title}}</a>"

  link: (scope, elem, attrs, ctrl, transclude)->
    scope.title = attrs.title

    contents = null
    transclude scope, (clone)->
      contents = clone

    scope.cancel = ->
      scope.modalInstance.dismiss("cancel")

    elem.on "click", ->
      scope.modalInstance = $modal.open(controller: ctrl, template: contents)
