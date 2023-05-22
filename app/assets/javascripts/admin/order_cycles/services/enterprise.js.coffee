angular.module('admin.orderCycles').factory('Enterprise', ($resource) ->
  Enterprise = $resource('/admin/enterprises/for_order_cycle/:enterprise_id.json', {}, {
    'index':
      method: 'GET'
      isArray: true
      params:
        order_cycle_id: '@order_cycle_id'
        coordinator_id: '@coordinator_id'
  })
  {
    Enterprise: Enterprise
    enterprises: {}
    producer_enterprises: []
    hub_enterprises: []
    loaded: false

    index: (params={}, callback=null) ->
    	Enterprise.index params, (data) =>
        for enterprise in data
          @enterprises[enterprise.id] = enterprise
          @producer_enterprises.push(enterprise) if enterprise.is_primary_producer
          @hub_enterprises.push(enterprise) if enterprise.sells == 'any'

        @loaded = true
        (callback || angular.noop)(@enterprises)

    	this.enterprises

    suppliedVariants: (enterprise_id) ->
      vs = (this.variantsOf(product) for product in this.enterprises[enterprise_id].supplied_products)
      [].concat vs...

    variantsOf: (product) ->
      if product.variants.length > 0
        variant.id for variant in product.variants
  })
