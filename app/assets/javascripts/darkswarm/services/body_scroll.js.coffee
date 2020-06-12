angular.module("Darkswarm").factory "BodyScroll", ($rootScope) ->
  new class BodyScroll
    disabled: false

    toggle: ->
      @disabled = !@disabled
      $rootScope.$broadcast "toggleBodyScroll"
