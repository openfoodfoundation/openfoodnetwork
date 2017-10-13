describe "OrdersAndFulfillmentsReport Service", ->
  OrdersAndFulfillmentsReport = uiGridGroupingConstants = null

  beforeEach ->
    module "admin.reports"
    module ($provide) ->
      $provide.value 'uiGridGroupingConstants', uiGridGroupingConstants
      null

    inject (_OrdersAndFulfillmentsReport_) ->
      OrdersAndFulfillmentsReport = _OrdersAndFulfillmentsReport_

  it 'Grid menu should be enabled', ->
    expect(OrdersAndFulfillmentsReport.gridOptions().enableGridMenu).toBe true


  it 'should have correct amount of columns by default', ->
    expect(OrdersAndFulfillmentsReport.gridOptions().columnDefs.length).toEqual 10

  it 'should have four types of different reports', ->
    expect(OrdersAndFulfillmentsReport.columnOptions().supplier_totals.length).toEqual 10
    expect(OrdersAndFulfillmentsReport.columnOptions().supplier_totals_by_distributor.length).toEqual 9
    expect(OrdersAndFulfillmentsReport.columnOptions().distributor_totals_by_supplier.length).toEqual 10
    expect(OrdersAndFulfillmentsReport.columnOptions().customer_totals.length).toEqual 35
