angular.module('admin.order_cycles').factory('Enterprise', ($resource) ->
  Enterprise = $resource('/admin/enterprises/for_order_cycle/:enterprise_id.json', {}, {'index': {method: 'GET', isArray: true}})

  {
    Enterprise: Enterprise
    enterprises: {}
    supplied_products: []
    loaded: false

    index: (callback=null) ->
    	service = this

    	Enterprise.index (data) ->
        for enterprise in data
          service.enterprises[enterprise.id] = enterprise

          for product in enterprise.supplied_products
            service.supplied_products.push(product)

        service.loaded = true
        (callback || angular.noop)(service.enterprises)

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