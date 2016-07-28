angular.module("admin.orderCycles").directive 'orderCyclesSelector', (OrderCycles, RequestMonitor) ->
  restrict: 'C'
  templateUrl: 'admin/order_cycles_selector.html'
  link: (scope, element, attr) ->
    scope.availableOptions =
      connectWith: '#selected-order-cycles .order-cycles'

    scope.selectedOptions =
      connectWith: '#available-order-cycles .order-cycles'
