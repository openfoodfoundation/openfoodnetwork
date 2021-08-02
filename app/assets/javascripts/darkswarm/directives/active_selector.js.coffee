angular.module('Darkswarm').directive "activeSelector",  ->
  # A generic selector that allows an object/scope to be toggled between active and inactive
  # Used in the filters, but hypothetically useable anywhere
  restrict: 'E'
  transclude: true
  replace: true
  templateUrl: 'active_selector.html'
  link: (scope, elem, attr)->
    unless scope.readOnly && scope.readOnly()
      scope.selector.emit = scope.emit
      elem.bind "click", ->
        scope.$apply ->
          scope.selector.active = !scope.selector.active
          # This function is a convention, e.g. a callback on the scope applied when active changes
          scope.emit() if scope.emit
