angular.module('Darkswarm').directive "darkerBackground", ->
  restrict: "A"
  link: (scope, elm, attr)->
    toggleClass = (value) ->
      elm.closest('.page-view').toggleClass("with-darker-background", value)

    toggleClass(true)

    # if an OrderCycle is selected, disable darker background
    scope.$watch 'order_cycle.order_cycle_id', (newvalue, oldvalue) ->
      toggleClass(false) if newvalue
