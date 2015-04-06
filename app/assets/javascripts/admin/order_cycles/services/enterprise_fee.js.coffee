angular.module('admin.order_cycles').factory('EnterpriseFee', ($resource) ->
  EnterpriseFee = $resource('/admin/enterprise_fees/for_order_cycle/:enterprise_fee_id.json', {},  {
    'index':
      method: 'GET'
      isArray: true
      params:
        order_cycle_id: '@order_cycle_id'
        coordinator_id: '@coordinator_id'
  })

  {
    EnterpriseFee: EnterpriseFee
    enterprise_fees: {}
    loaded: false

    index: (params={}) ->
      service = this
      EnterpriseFee.index params, (data) ->
        service.enterprise_fees = data
        service.loaded = true

    forEnterprise: (enterprise_id) ->
      enterprise_fee for enterprise_fee in this.enterprise_fees when enterprise_fee.enterprise_id == enterprise_id
  })
