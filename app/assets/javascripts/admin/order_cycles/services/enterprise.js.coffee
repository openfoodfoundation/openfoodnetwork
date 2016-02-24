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
    supplied_products: []
    loaded: false

    index: (params={}, callback=null) ->
    	Enterprise.index params, (data) =>
        for enterprise in data
          @enterprises[enterprise.id] = enterprise
          @producer_enterprises.push(enterprise) if enterprise.is_primary_producer
          @hub_enterprises.push(enterprise) if enterprise.sells == 'any'

          for product in enterprise.supplied_products
            @supplied_products.push(product)

        @loaded = true
        (callback || angular.noop)(@enterprises)

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
  })
