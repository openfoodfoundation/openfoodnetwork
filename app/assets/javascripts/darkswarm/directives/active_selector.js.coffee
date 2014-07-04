Darkswarm.directive "activeSelector",  ->
  restrict: 'E'
  transclude: true
  replace: true
  templateUrl: 'active_selector.html'
  link: (scope, elem, attr)->
    elem.bind "click", ->
      scope.$apply ->
        elem.toggleClass "active"
        scope.selector.active = !scope.selector.active 
