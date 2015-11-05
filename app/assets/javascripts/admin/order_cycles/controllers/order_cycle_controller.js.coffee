angular.module('admin.order_cycles', ['ngResource'])
  .controller('AdminCreateOrderCycleCtrl', ['$scope', '$filter', 'OrderCycle', 'Enterprise', 'EnterpriseFee', 'ocInstance', ($scope, $filter, OrderCycle, Enterprise, EnterpriseFee, ocInstance) ->
    $scope.enterprises = Enterprise.index(coordinator_id: ocInstance.coordinator_id)
    $scope.supplied_products = Enterprise.supplied_products
    $scope.enterprise_fees = EnterpriseFee.index(coordinator_id: ocInstance.coordinator_id)

    $scope.order_cycle = OrderCycle.new({ coordinator_id: ocInstance.coordinator_id})

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

    $scope.incomingExchangeVariantsFor = (enterprise_id) ->
      $filter('filterExchangeVariants')(OrderCycle.incomingExchangesVariants(), $scope.order_cycle.visible_variants_for_outgoing_exchanges[enterprise_id])

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.enterprisesWithFees = ->
      $scope.enterprises[id] for id in OrderCycle.participatingEnterpriseIds() when $scope.enterpriseFeesForEnterprise(id).length > 0

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

    $scope.submit = (event) ->
      event.preventDefault()
      OrderCycle.create()
  ])

  .controller('AdminEditOrderCycleCtrl', ['$scope', '$filter', '$location', 'OrderCycle', 'Enterprise', 'EnterpriseFee', ($scope, $filter, $location, OrderCycle, Enterprise, EnterpriseFee) ->
    order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
    $scope.enterprises = Enterprise.index(order_cycle_id: order_cycle_id)
    $scope.supplied_products = Enterprise.supplied_products
    $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: order_cycle_id)

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

    $scope.incomingExchangeVariantsFor = (enterprise_id) ->
      $filter('filterExchangeVariants')(OrderCycle.incomingExchangesVariants(), $scope.order_cycle.visible_variants_for_outgoing_exchanges[enterprise_id])

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.enterprisesWithFees = ->
      $scope.enterprises[id] for id in OrderCycle.participatingEnterpriseIds() when $scope.enterpriseFeesForEnterprise(id).length > 0

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

    $scope.submit = (event) ->
      event.preventDefault()
      OrderCycle.update()
  ])

  .config(['$httpProvider', ($httpProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
  ])

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
