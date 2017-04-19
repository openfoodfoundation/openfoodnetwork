describe "OrdersAndDistributorsReport Service", ->
  OrdersAndDistributorsReport = uiGridGroupingConstants = null

  beforeEach ->
    module "admin.reports"
    module ($provide) ->
      $provide.value 'uiGridGroupingConstants', uiGridGroupingConstants
      null

    inject (_OrdersAndDistributorsReport_) ->
      OrdersAndDistributorsReport = _OrdersAndDistributorsReport_

  it 'should have correct amount of columns', ->
    expect(OrdersAndDistributorsReport.gridOptions().columnDefs.length).toEqual 19

  it 'Grid menu should be enabled', ->
    expect(OrdersAndDistributorsReport.gridOptions().enableGridMenu).toBe true
