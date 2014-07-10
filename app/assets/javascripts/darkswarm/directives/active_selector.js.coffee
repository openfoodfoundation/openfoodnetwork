Darkswarm.directive "activeSelector",  ->
  restrict: 'E'
  transclude: true
  replace: true
  templateUrl: 'active_selector.html'
  link: (scope, elem, attr)->
    scope.selector.emit = scope.emit
    elem.bind "click", ->
      scope.$apply ->
        scope.selector.active = !scope.selector.active 
        scope.emit()
  
