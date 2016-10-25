angular.module("admin.reports").controller "ordersAndFulfillmentsController", ($scope, $http, $filter, Enterprises, OrderCycles, LineItems, Orders, Products, Variants) ->
  $scope.enterprises = Enterprises.all
  $scope.orderCycles = OrderCycles.all

  $scope.gridOptions =
    enableSorting: true
    enableGridMenu: true
    enableFiltering: true
    enableColumnResizing: true
    columnDefs: [
      { field: 'id',                    displayName: 'ID',       width: '10%' }
      { field: 'number',                displayName: 'Order',    width: '20%' }
      # { field: 'product.producer.name', displayName: 'Producer', width: '10%' }
      { field: 'product.name',          displayName: 'Product',  width: '20%' }
      { field: 'full_name',             displayName: 'Variant',  width: '25%' }
      { field: 'quantity',              displayName: 'Qty', width: '5%' }
      { field: 'price',                 displayName: 'Price',    width: '15%' }
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


  data = $http.get('/admin/reports/orders_and_fulfillment.json').success (data) ->
    LineItems.load data.line_items
    Orders.load data.orders
    Products.load data.products
    Variants.load data.variants
    LineItems.linkToOrders()
    order.$$treeLevel = 0 for order in Orders.all
    # lineItem.$$treeLevel = 1 for lineItem in LineItems.all
    data = $filter('orderBy')(LineItems.all.concat(Orders.all), [(item) ->
      if item.order? then item.order.id else item.id
    , "$$treeLevel"])
    $scope.gridOptions.data = data
