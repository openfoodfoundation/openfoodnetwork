angular.module('Darkswarm').factory 'CurrentOrder', (currentOrder) ->
  # Populate Currentorder.order from json in page. This is probably redundant now.
  new class CurrentOrder
    order: currentOrder
