angular.module('order_cycle', ['ngResource'])
  .controller('AdminCreateOrderCycleCtrl', ['$scope', 'OrderCycle', 'Enterprise', ($scope, OrderCycle, Enterprise) ->
    $scope.enterprises = Enterprise.index()
    $scope.supplied_products = Enterprise.supplied_products

    $scope.order_cycle = OrderCycle.order_cycle

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.enterpriseTotalVariants = (enterprise) ->
      Enterprise.totalVariants(enterprise)

    $scope.productSuppliedToOrderCycle = (product) ->
      OrderCycle.productSuppliedToOrderCycle(product)

    $scope.variantSuppliedToOrderCycle = (variant) ->
      OrderCycle.variantSuppliedToOrderCycle(variant)

    $scope.incomingExchangesVariants = ->
      OrderCycle.incomingExchangesVariants()

    $scope.toggleProducts = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.toggleProducts(exchange)

    $scope.addSupplier = ($event) ->
      $event.preventDefault()
      OrderCycle.addSupplier($scope.new_supplier_id)

    $scope.addDistributor = ($event) ->
      $event.preventDefault()
      OrderCycle.addDistributor($scope.new_distributor_id)

    $scope.submit = ->
      OrderCycle.create()
  ])

  .controller('AdminEditOrderCycleCtrl', ['$scope', '$location', 'OrderCycle', 'Enterprise', ($scope, $location, OrderCycle, Enterprise) ->
    $scope.enterprises = Enterprise.index()
    $scope.supplied_products = Enterprise.supplied_products

    order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
    $scope.order_cycle = OrderCycle.load(order_cycle_id)

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.enterpriseTotalVariants = (enterprise) ->
      Enterprise.totalVariants(enterprise)

    $scope.productSuppliedToOrderCycle = (product) ->
      OrderCycle.productSuppliedToOrderCycle(product)

    $scope.variantSuppliedToOrderCycle = (variant) ->
      OrderCycle.variantSuppliedToOrderCycle(variant)

    $scope.incomingExchangesVariants = ->
      OrderCycle.incomingExchangesVariants()

    $scope.toggleProducts = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.toggleProducts(exchange)

    $scope.addSupplier = ($event) ->
      $event.preventDefault()
      OrderCycle.addSupplier($scope.new_supplier_id)

    $scope.addDistributor = ($event) ->
      $event.preventDefault()
      OrderCycle.addDistributor($scope.new_distributor_id)

    $scope.submit = ->
      OrderCycle.update()
  ])

  .config(['$httpProvider', ($httpProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
  ])

  .factory('OrderCycle', ['$resource', '$window', ($resource, $window) ->
    OrderCycle = $resource '/admin/order_cycles/:order_cycle_id.json', {}, {
      'index':  { method: 'GET', isArray: true}
  		'create': { method: 'POST'}
  		'update': { method: 'PUT'}}

    {
      order_cycle:
        incoming_exchanges: []
   	    outgoing_exchanges: []

      exchangeSelectedVariants: (exchange) ->
        numActiveVariants = 0
        numActiveVariants++ for id, active of exchange.variants when active
        numActiveVariants

      toggleProducts: (exchange) ->
      	exchange.showProducts = !exchange.showProducts

      addSupplier: (new_supplier_id) ->
      	this.order_cycle.incoming_exchanges.push({enterprise_id: new_supplier_id, active: true, variants: {}})

      addDistributor: (new_distributor_id) ->
      	this.order_cycle.outgoing_exchanges.push({enterprise_id: new_distributor_id, active: true, variants: {}})

      productSuppliedToOrderCycle: (product) ->
        product_variant_ids = (variant.id for variant in product.variants)
        variant_ids = [product.master_id].concat(product_variant_ids)
        incomingExchangesVariants = this.incomingExchangesVariants()

        # TODO: This is an O(n^2) implementation of set intersection and thus is slooow.
        # Use a better algorithm if needed.
        # Also, incomingExchangesVariants is called every time, when it only needs to be
        # called once per change to incoming variants. Some sort of caching?
        ids = (variant_id for variant_id in variant_ids when incomingExchangesVariants.indexOf(variant_id) != -1)
        ids.length > 0

      variantSuppliedToOrderCycle: (variant) ->
        this.incomingExchangesVariants().indexOf(variant.id) != -1

      incomingExchangesVariants: ->
        variant_ids = []

        for exchange in this.order_cycle.incoming_exchanges
          variant_ids.push(parseInt(id)) for id, active of exchange.variants when active
        variant_ids

      load: (order_cycle_id) ->
      	service = this

      	OrderCycle.get {order_cycle_id: order_cycle_id}, (oc) ->
      	  angular.extend(service.order_cycle, oc)
      	  service.order_cycle.incoming_exchanges = []
      	  service.order_cycle.outgoing_exchanges = []
      	  for exchange in service.order_cycle.exchanges
      	    if exchange.sender_id == service.order_cycle.coordinator_id
      	      angular.extend(exchange, {enterprise_id: exchange.receiver_id, active: true})
      	      delete(exchange.sender_id)
      	      service.order_cycle.outgoing_exchanges.push(exchange)
      
      	    else if exchange.receiver_id == service.order_cycle.coordinator_id
      	      angular.extend(exchange, {enterprise_id: exchange.sender_id, active: true})
      	      delete(exchange.receiver_id)
      	      service.order_cycle.incoming_exchanges.push(exchange)
      
      	    else
      	      console.log('Exchange between two enterprises, neither of which is coordinator!')
      
      	  delete(service.order_cycle.exchanges)

        this.order_cycle

      create: ->
      	this.removeInactiveExchanges()

      	oc = new OrderCycle({order_cycle: this.order_cycle})
      	oc.$create (data) ->
      	  if data['success']
      	    $window.location = '/admin/order_cycles'
      	  else
      	    console.log('fail')

      update: ->
      	this.removeInactiveExchanges()

      	oc = new OrderCycle({order_cycle: this.order_cycle})
      	oc.$update {order_cycle_id: this.order_cycle.id}, (data) ->
      	  if data['success']
      	    $window.location = '/admin/order_cycles'
      	  else
      	    console.log('fail')

      removeInactiveExchanges: ->
        this.order_cycle.incoming_exchanges =
          (exchange for exchange in this.order_cycle.incoming_exchanges when exchange.active)
        this.order_cycle.outgoing_exchanges =
          (exchange for exchange in this.order_cycle.outgoing_exchanges when exchange.active)
    }])

  .factory('Enterprise', ['$resource', ($resource) ->
    Enterprise = $resource('/admin/enterprises/:enterprise_id.json', {}, {'index': {method: 'GET', isArray: true}})

    {
      Enterprise: Enterprise
      enterprises: {}
      supplied_products: []

      index: ->
      	service = this

      	Enterprise.index (data) ->
          for enterprise in data
            service.enterprises[enterprise.id] = enterprise

            for product in enterprise.supplied_products
              service.supplied_products.push(product)

      	this.enterprises

      totalVariants: (enterprise) ->
        numVariants = 0

        counts = for product in enterprise.supplied_products
          numVariants += if product.variants.length == 0 then 1 else product.variants.length

        numVariants
    }])


  .directive('datetimepicker', ['$parse', ($parse) ->
    (scope, element, attrs) ->
      # using $parse instead of scope[attrs.datetimepicker] for cases
      # where attrs.datetimepicker is 'foo.bar.lol'
      $(element).datetimepicker
      	dateFormat: 'yy-mm-dd'
      	timeFormat: 'HH:mm:ss'
      	showOn: "button"
      	buttonImage: "<%= asset_path 'datepicker/cal.gif' %>"
      	buttonImageOnly: true
      	stepMinute: 15
      	onSelect: (dateText, inst) ->
      	  scope.$apply ->
      	    parsed = $parse(attrs.datetimepicker)
      	    parsed.assign(scope, dateText)
    ])
