angular.module("admin.reports").controller "ordersAndFulfillmentsController", ($scope, $http, Enterprises, OrderCycles, LineItems) ->
  $scope.enterprises = Enterprises.all
  $scope.orderCycles = OrderCycles.all

  $scope.gridOptions =
    columnDefs: [
      { field: 'product.producer.name', displayName: 'Producer',  width: '20%' }
      { field: 'product.name',          displayName: 'Product',  width: '20%' }
      { field: 'full_name',             displayName: 'Variant',  width: '40%' }
      { field: 'quantity',              displayName: 'Quantity',  width: '20%' }
      # { field: '',  displayName: 'Quantity',  width: '80%' }
      # { field: 'product.name',  displayName: 'Quantity',  width: '80%' }
      # { field: 'product.name',  displayName: 'Quantity',  width: '80%' }
    ]

  #
  #           [ proc { |line_items| line_items.first.product.supplier.name },
  #             proc { |line_items| line_items.first.product.name },
  #             proc { |line_items| line_items.first.full_name },
  #             proc { |line_items| line_items.sum { |li| li.quantity } },
  #             proc { |line_items| total_units(line_items) },
  #             proc { |line_items| line_items.first.price },
  #             proc { |line_items| line_items.sum { |li| li.amount } },
  #             proc { |line_items| "" },
  #             proc { |line_items| "incoming transport" } ]
  #
  # ["Producer", "Product", "Variant", "Amount", "Total Units", "Curr. Cost per Unit", "Total Cost", "Status", "Incoming Transport"]


  data = $http.get('/admin/reports/orders_and_fulfillment.json').then (response) ->
    LineItems.load response.data.line_items
    Orders.load response.data.orders
    Products.load response.data.products
    Variants.load response.data.variants
    Linker.lineItemsToOrders()
    $scope.gridOptions.data = LineItems.all
