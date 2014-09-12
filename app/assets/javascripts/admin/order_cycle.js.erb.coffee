angular.module('order_cycle', ['ngResource'])
  .controller('AdminCreateOrderCycleCtrl', ['$scope', 'OrderCycle', 'Enterprise', 'EnterpriseFee', ($scope, OrderCycle, Enterprise, EnterpriseFee) ->
    $scope.enterprises = Enterprise.index()
    $scope.supplied_products = Enterprise.supplied_products
    $scope.enterprise_fees = EnterpriseFee.index()

    $scope.order_cycle = OrderCycle.order_cycle

    $scope.loaded = ->
      Enterprise.loaded && EnterpriseFee.loaded

    $scope.suppliedVariants = (enterprise_id) ->
      Enterprise.suppliedVariants(enterprise_id)

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.setExchangeVariants = (exchange, variants, selected) ->
      OrderCycle.setExchangeVariants(exchange, variants, selected)

    $scope.enterpriseTotalVariants = (enterprise) ->
      Enterprise.totalVariants(enterprise)

    $scope.productSuppliedToOrderCycle = (product) ->
      OrderCycle.productSuppliedToOrderCycle(product)

    $scope.variantSuppliedToOrderCycle = (variant) ->
      OrderCycle.variantSuppliedToOrderCycle(variant)

    $scope.incomingExchangesVariants = ->
      OrderCycle.incomingExchangesVariants()

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.participatingEnterprises = ->
      $scope.enterprises[id] for id in OrderCycle.participatingEnterpriseIds()

    $scope.toggleProducts = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.toggleProducts(exchange)

    $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
      EnterpriseFee.forEnterprise(parseInt(enterprise_id))

    $scope.addSupplier = ($event) ->
      $event.preventDefault()
      OrderCycle.addSupplier($scope.new_supplier_id)

    $scope.addDistributor = ($event) ->
      $event.preventDefault()
      OrderCycle.addDistributor($scope.new_distributor_id)

    $scope.removeExchange = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.removeExchange(exchange)

    $scope.addCoordinatorFee = ($event) ->
      $event.preventDefault()
      OrderCycle.addCoordinatorFee()

    $scope.removeCoordinatorFee = ($event, index) ->
      $event.preventDefault()
      OrderCycle.removeCoordinatorFee(index)

    $scope.addExchangeFee = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.addExchangeFee(exchange)

    $scope.removeExchangeFee = ($event, exchange, index) ->
      $event.preventDefault()
      OrderCycle.removeExchangeFee(exchange, index)

    $scope.removeDistributionOfVariant = (variant_id) ->
      OrderCycle.removeDistributionOfVariant(variant_id)

    $scope.submit = ->
      OrderCycle.create()
  ])

  .controller('AdminEditOrderCycleCtrl', ['$scope', '$location', 'OrderCycle', 'Enterprise', 'EnterpriseFee', ($scope, $location, OrderCycle, Enterprise, EnterpriseFee) ->
    $scope.enterprises = Enterprise.index()
    $scope.supplied_products = Enterprise.supplied_products
    $scope.enterprise_fees = EnterpriseFee.index()

    order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
    $scope.order_cycle = OrderCycle.load(order_cycle_id)

    $scope.loaded = ->
      Enterprise.loaded && EnterpriseFee.loaded && OrderCycle.loaded

    $scope.suppliedVariants = (enterprise_id) ->
      Enterprise.suppliedVariants(enterprise_id)

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.setExchangeVariants = (exchange, variants, selected) ->
      OrderCycle.setExchangeVariants(exchange, variants, selected)

    $scope.enterpriseTotalVariants = (enterprise) ->
      Enterprise.totalVariants(enterprise)

    $scope.productSuppliedToOrderCycle = (product) ->
      OrderCycle.productSuppliedToOrderCycle(product)

    $scope.variantSuppliedToOrderCycle = (variant) ->
      OrderCycle.variantSuppliedToOrderCycle(variant)

    $scope.incomingExchangesVariants = ->
      OrderCycle.incomingExchangesVariants()

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.participatingEnterprises = ->
      $scope.enterprises[id] for id in OrderCycle.participatingEnterpriseIds()

    $scope.toggleProducts = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.toggleProducts(exchange)

    $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
      EnterpriseFee.forEnterprise(parseInt(enterprise_id))

    $scope.addSupplier = ($event) ->
      $event.preventDefault()
      OrderCycle.addSupplier($scope.new_supplier_id)

    $scope.addDistributor = ($event) ->
      $event.preventDefault()
      OrderCycle.addDistributor($scope.new_distributor_id)

    $scope.removeExchange = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.removeExchange(exchange)

    $scope.addCoordinatorFee = ($event) ->
      $event.preventDefault()
      OrderCycle.addCoordinatorFee()

    $scope.removeCoordinatorFee = ($event, index) ->
      $event.preventDefault()
      OrderCycle.removeCoordinatorFee(index)

    $scope.addExchangeFee = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.addExchangeFee(exchange)

    $scope.removeExchangeFee = ($event, exchange, index) ->
      $event.preventDefault()
      OrderCycle.removeExchangeFee(exchange, index)

    $scope.removeDistributionOfVariant = (variant_id) ->
      OrderCycle.removeDistributionOfVariant(variant_id)

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
        coordinator_fees: []

      loaded: false

      exchangeSelectedVariants: (exchange) ->
        numActiveVariants = 0
        numActiveVariants++ for id, active of exchange.variants when active
        numActiveVariants

      exchangeDirection: (exchange) ->
        if this.order_cycle.incoming_exchanges.indexOf(exchange) == -1 then 'outgoing' else 'incoming'

      toggleProducts: (exchange) ->
      	exchange.showProducts = !exchange.showProducts

      setExchangeVariants: (exchange, variants, selected) ->
        exchange.variants[variant] = selected for variant in variants

      addSupplier: (new_supplier_id) ->
      	this.order_cycle.incoming_exchanges.push({enterprise_id: new_supplier_id, incoming: true, active: true, variants: {}, enterprise_fees: []})

      addDistributor: (new_distributor_id) ->
      	this.order_cycle.outgoing_exchanges.push({enterprise_id: new_distributor_id, incoming: false, active: true, variants: {}, enterprise_fees: []})

      removeExchange: (exchange) ->
        if exchange.incoming
          incoming_index = this.order_cycle.incoming_exchanges.indexOf exchange
          this.order_cycle.incoming_exchanges.splice(incoming_index, 1)
          this.removeDistributionOfVariant(variant_id) for variant_id, active of exchange.variants when active
        else
          outgoing_index = this.order_cycle.outgoing_exchanges.indexOf exchange
          this.order_cycle.outgoing_exchanges.splice(outgoing_index, 1) if outgoing_index > -1

      addCoordinatorFee: ->
        this.order_cycle.coordinator_fees.push({})

      removeCoordinatorFee: (index) ->
        this.order_cycle.coordinator_fees.splice(index, 1)

      addExchangeFee: (exchange) ->
        exchange.enterprise_fees.push({})

      removeExchangeFee: (exchange, index) ->
        exchange.enterprise_fees.splice(index, 1)

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

      participatingEnterpriseIds: ->
        suppliers = (exchange.enterprise_id for exchange in this.order_cycle.incoming_exchanges)
        distributors = (exchange.enterprise_id for exchange in this.order_cycle.outgoing_exchanges)
        jQuery.unique(suppliers.concat(distributors)).sort()

      removeDistributionOfVariant: (variant_id) ->
        for exchange in this.order_cycle.outgoing_exchanges
          exchange.variants[variant_id] = false

      load: (order_cycle_id) ->
        service = this
        OrderCycle.get {order_cycle_id: order_cycle_id}, (oc) ->
      	  angular.extend(service.order_cycle, oc)
      	  service.order_cycle.incoming_exchanges = []
      	  service.order_cycle.outgoing_exchanges = []
      	  for exchange in service.order_cycle.exchanges
      	    if exchange.incoming
      	      angular.extend(exchange, {enterprise_id: exchange.sender_id, active: true})
      	      delete(exchange.receiver_id)
      	      service.order_cycle.incoming_exchanges.push(exchange)
      
      	    else
      	      angular.extend(exchange, {enterprise_id: exchange.receiver_id, active: true})
      	      delete(exchange.sender_id)
      	      service.order_cycle.outgoing_exchanges.push(exchange)
      
          delete(service.order_cycle.exchanges)
          service.loaded = true

        this.order_cycle

      create: ->
      	oc = new OrderCycle({order_cycle: this.dataForSubmit()})
      	oc.$create (data) ->
      	  if data['success']
      	    $window.location = '/admin/order_cycles'
      	  else
            console.log('Failed to create order cycle')

      update: ->
      	oc = new OrderCycle({order_cycle: this.dataForSubmit()})
      	oc.$update {order_cycle_id: this.order_cycle.id}, (data) ->
      	  if data['success']
      	    $window.location = '/admin/order_cycles'
      	  else
            console.log('Failed to update order cycle')

      dataForSubmit: ->
        data = this.deepCopy()
        data = this.removeInactiveExchanges(data)
        data = this.translateCoordinatorFees(data)
        data = this.translateExchangeFees(data)
        data

      deepCopy: ->
        data = angular.extend({}, this.order_cycle)

        # Copy exchanges
        data.incoming_exchanges = (angular.extend {}, exchange for exchange in this.order_cycle.incoming_exchanges) if this.order_cycle.incoming_exchanges?
        data.outgoing_exchanges = (angular.extend {}, exchange for exchange in this.order_cycle.outgoing_exchanges) if this.order_cycle.outgoing_exchanges?

        # Copy exchange fees
        all_exchanges = (data.incoming_exchanges || []) + (data.outgoing_exchanges || [])
        for exchange in all_exchanges
          if exchange.enterprise_fees?
            exchange.enterprise_fees = (angular.extend {}, fee for fee in exchange.enterprise_fees)

        data

      removeInactiveExchanges: (order_cycle) ->
        order_cycle.incoming_exchanges =
          (exchange for exchange in order_cycle.incoming_exchanges when exchange.active)
        order_cycle.outgoing_exchanges =
          (exchange for exchange in order_cycle.outgoing_exchanges when exchange.active)
        order_cycle

      translateCoordinatorFees: (order_cycle) ->
        order_cycle.coordinator_fee_ids = (fee.id for fee in order_cycle.coordinator_fees)
        delete order_cycle.coordinator_fees
        order_cycle

      translateExchangeFees: (order_cycle) ->
        for exchange in order_cycle.incoming_exchanges
          exchange.enterprise_fee_ids = (fee.id for fee in exchange.enterprise_fees)
          delete exchange.enterprise_fees
        for exchange in order_cycle.outgoing_exchanges
          exchange.enterprise_fee_ids = (fee.id for fee in exchange.enterprise_fees)
          delete exchange.enterprise_fees
        order_cycle
    }])

  .factory('Enterprise', ['$resource', ($resource) ->
    Enterprise = $resource('/admin/enterprises/for_order_cycle/:enterprise_id.json', {}, {'index': {method: 'GET', isArray: true}})

    {
      Enterprise: Enterprise
      enterprises: {}
      supplied_products: []
      loaded: false

      index: ->
      	service = this

      	Enterprise.index (data) ->
          for enterprise in data
            service.enterprises[enterprise.id] = enterprise

            for product in enterprise.supplied_products
              service.supplied_products.push(product)

          service.loaded = true

      	this.enterprises

      suppliedVariants: (enterprise_id) ->
        vs = (this.variantsOf(product) for product in this.enterprises[enterprise_id].supplied_products)
        [].concat vs...

      variantsOf: (product) ->
        if product.variants.length > 0
          variant.id for variant in product.variants
        else
          [product.master_id]

      totalVariants: (enterprise) ->
        numVariants = 0

        if enterprise
          counts = for product in enterprise.supplied_products
            numVariants += if product.variants.length == 0 then 1 else product.variants.length

        numVariants
    }])

  .factory('EnterpriseFee', ['$resource', ($resource) ->
    EnterpriseFee = $resource('/admin/enterprise_fees/:enterprise_fee_id.json', {}, {'index': {method: 'GET', isArray: true}})

    {
      EnterpriseFee: EnterpriseFee
      enterprise_fees: {}
      loaded: false

      index: ->
        service = this
        EnterpriseFee.index (data) ->
          service.enterprise_fees = data
          service.loaded = true

      forEnterprise: (enterprise_id) ->
        enterprise_fee for enterprise_fee in this.enterprise_fees when enterprise_fee.enterprise_id == enterprise_id
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

  .directive('ofnOnChange', ->
    (scope, element, attrs) ->
      element.bind 'change', ->
        scope.$apply(attrs.ofnOnChange)
    )

  .directive('ofnSyncDistributions', ->
    (scope, element, attrs) ->
      element.bind 'change', ->
        if !$(this).is(':checked')
          scope.$apply ->
            scope.removeDistributionOfVariant(attrs.ofnSyncDistributions)
    )
