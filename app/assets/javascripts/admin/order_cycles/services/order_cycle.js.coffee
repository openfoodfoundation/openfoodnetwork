angular.module('admin.order_cycles').factory('OrderCycle', ($resource, $window) ->
  OrderCycle = $resource '/admin/order_cycles/:action_name/:order_cycle_id.json', {}, {
    'index':  { method: 'GET', isArray: true}
    'new'   : { method: 'GET', params: { action_name: "new" } }
		'create': { method: 'POST'}
		'update': { method: 'PUT'}}

  {
    order_cycle: {}

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
      direction = if exchange.incoming then "incoming" else "outgoing"
      editable = @order_cycle["editable_variants_for_#{direction}_exchanges"][exchange.enterprise_id] || []
      exchange.variants[variant] = selected for variant in variants when variant in editable

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

    new: (params, callback=null) ->
      OrderCycle.new params, (oc) =>
        delete oc.$promise
        delete oc.$resolved
        angular.extend(@order_cycle, oc)
        @order_cycle.incoming_exchanges = []
        @order_cycle.outgoing_exchanges = []
        delete(@order_cycle.exchanges)
        @loaded = true

        (callback || angular.noop)(@order_cycle)

      @order_cycle

    load: (order_cycle_id, callback=null) ->
      service = this
      OrderCycle.get {order_cycle_id: order_cycle_id}, (oc) ->
        delete oc.$promise
        delete oc.$resolved
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

        (callback || angular.noop)(service.order_cycle)

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
      data = this.stripNonSubmittableAttributes(data)
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

    stripNonSubmittableAttributes: (order_cycle) ->
      delete order_cycle.id
      delete order_cycle.viewing_as_coordinator
      delete order_cycle.editable_variants_for_incoming_exchanges
      delete order_cycle.editable_variants_for_outgoing_exchanges
      delete order_cycle.visible_variants_for_outgoing_exchanges
      order_cycle

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

    # In the simple UI, we don't list outgoing products. Instead, all products are considered
    # part of both incoming and outgoing enterprises. This method mirrors the former to the
    # latter **for order cycles with a single incoming and outgoing exchange only**.
    mirrorIncomingToOutgoingProducts: ->
      incoming = this.order_cycle.incoming_exchanges[0]
      outgoing = this.order_cycle.outgoing_exchanges[0]

      for id, active of incoming.variants
        outgoing.variants[id] = active
  })
