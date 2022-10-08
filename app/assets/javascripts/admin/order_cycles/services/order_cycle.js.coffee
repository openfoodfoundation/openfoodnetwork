angular.module('admin.orderCycles').factory 'OrderCycle', ($resource, $window, $timeout, StatusMessage, Panels, Enterprise) ->
  OrderCycleResource = $resource '/admin/order_cycles/:action_name/:order_cycle_id.json', {}, {
    'index':  { method: 'GET', isArray: true}
    'new'   : { method: 'GET', params: { action_name: "new" } }
		'create': { method: 'POST'}
		'update': { method: 'PUT'}}

  new class OrderCycle
    order_cycle: {incoming_exchanges: [], outgoing_exchanges: []}
    showProducts: {incoming: false, outgoing: false}

    loaded: false

    exchangeIds: (direction) ->
      parseInt(exchange.enterprise_id) for exchange in @exchangesByDirection(direction)

    novelSupplier: (enterprise) =>
      id = enterprise?.id || parseInt(enterprise)
      @exchangeIds('incoming').indexOf(id) == -1

    novelDistributor: (enterprise) =>
      id = enterprise?.id || parseInt(enterprise)
      @exchangeIds('outgoing').indexOf(id) == -1

    exchangeSelectedVariants: (exchange) ->
      numActiveVariants = 0
      numActiveVariants++ for id, active of exchange.variants when active
      numActiveVariants

    exchangeDirection: (exchange) ->
      if this.order_cycle.incoming_exchanges.indexOf(exchange) == -1 then 'outgoing' else 'incoming'

    toggleAllProducts: (direction) ->
      this.showProducts[direction] = !this.showProducts[direction]
      state = if this.showProducts[direction] then "open" else "closed"
      exchanges = this.exchangesByDirection(direction)
      Panels.toggle(exchange,'products',state) for exchange in exchanges

    setExchangeVariants: (exchange, variants, selected) ->
      direction = if exchange.incoming then "incoming" else "outgoing"
      editable = @order_cycle["editable_variants_for_#{direction}_exchanges"][exchange.enterprise_id] || []
      for variant in variants when variant in editable
        exchange.variants[variant] = selected
        @removeDistributionOfVariant(variant.id) if exchange.incoming


    addSupplier: (new_supplier_id, callback) ->
      this.order_cycle.incoming_exchanges.push({enterprise_id: new_supplier_id, incoming: true, active: true, variants: {}, enterprise_fees: []})
      $timeout ->
        (callback || angular.noop)()

    addDistributor: (new_distributor_id, callback) ->
      exchange = { enterprise_id: new_distributor_id, incoming: false, active: true, variants: {}, enterprise_fees: [] }
      if (Enterprise.hub_enterprises.length == 1)
        editable = this.order_cycle["editable_variants_for_outgoing_exchanges"][new_distributor_id] || []
        variants = this.incomingExchangesVariants()
        for variant in variants when variant in editable
          exchange.variants[variant] = true

      this.order_cycle.outgoing_exchanges.push(exchange)
      $timeout ->
        (callback || angular.noop)()

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

    variantSuppliedToOrderCycle: (variant) ->
      this.incomingExchangesVariants().indexOf(variant.id) != -1

    incomingExchangesVariants: ->
      variant_ids = []

      for exchange in this.order_cycle.incoming_exchanges
        variant_ids.push(parseInt(id)) for id, active of exchange.variants when active
      variant_ids

    participatingEnterpriseIds: ->
      suppliers = (parseInt(exchange.enterprise_id) for exchange in this.order_cycle.incoming_exchanges)
      distributors = (parseInt(exchange.enterprise_id) for exchange in this.order_cycle.outgoing_exchanges)
      Array.from(new Set([suppliers..., distributors...]))

    exchangesByDirection: (direction) ->
      if direction == 'incoming'
        this.order_cycle.incoming_exchanges
      else
        this.order_cycle.outgoing_exchanges

    removeDistributionOfVariant: (variant_id) ->
      for exchange in this.order_cycle.outgoing_exchanges
        exchange.variants[variant_id] = false

    new: (params, callback=null) ->
      OrderCycleResource.new params, (oc) =>
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
      OrderCycleResource.get {order_cycle_id: order_cycle_id}, (oc) ->
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

        $timeout ->
          (callback || angular.noop)(service.order_cycle)

      this.order_cycle

    create: (destination) ->
      oc = new OrderCycleResource({order_cycle: this.dataForSubmit()})
      oc.$create (data) ->
        if destination? && destination.length != 0
          $window.location = destination
        else if data.edit_path?
          $window.location = data.edit_path
      , (response) ->
        if response.data.errors?
          StatusMessage.display('failure', response.data.errors[0])
        else
          StatusMessage.display('failure', t('js.order_cycles.create_failure'))

    update: (destination, form) ->
      oc = new OrderCycleResource({order_cycle: this.dataForSubmit()})
      oc.$update {order_cycle_id: this.order_cycle.id, reloading: (if destination? then 1 else 0)}, (data) =>
        form.$setPristine() if form
        if destination?
          $window.location = destination
        else
          StatusMessage.display 'success', t('js.order_cycles.update_success')
      , (response) ->
        if response.data.errors?
          StatusMessage.display('failure', response.data.errors[0])
        else
          StatusMessage.display('failure', t('js.order_cycles.update_failure'))

    confirmNoDistributors: ->
      if @order_cycle.outgoing_exchanges.length == 0
        confirm t('js.order_cycles.no_distributors')
      else
        true

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
      delete order_cycle.subscriptions_count
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
