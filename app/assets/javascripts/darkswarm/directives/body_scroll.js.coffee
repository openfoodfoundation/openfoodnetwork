Darkswarm.directive "bodyScroll", ($rootScope, BodyScroll) ->
  restrict: 'A'
  scope: true
  link: (scope, elem, attrs) ->
    $rootScope.$on "toggleBodyScroll", ->
      if BodyScroll.disabled
        elem.addClass "disable-scroll"
      else
        elem.removeClass "disable-scroll"
