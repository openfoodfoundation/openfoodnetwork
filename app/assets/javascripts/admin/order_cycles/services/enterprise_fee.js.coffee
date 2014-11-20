angular.module('admin.order_cycles').factory('EnterpriseFee', ($resource) ->
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
  })

