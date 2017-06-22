describe "BulkCoopReport Service", ->
  BulkCoopReport = uiGridGroupingConstants = null

  beforeEach ->
    module "admin.reports"
    module ($provide) ->
      $provide.value 'uiGridGroupingConstants', uiGridGroupingConstants
      null

    inject (_BulkCoopReport_) ->
      BulkCoopReport = _BulkCoopReport_

  it 'Grid menu should be enabled', ->
    expect(BulkCoopReport.gridOptions().enableGridMenu).toBe true

  it 'should have correct amount of columns', ->
    expect(BulkCoopReport.gridOptions().columnDefs.length).toEqual 12

  it 'should have four types of different reports', ->
    expect(BulkCoopReport.columnOptions().supplier_report.length).toEqual 12
    expect(BulkCoopReport.columnOptions().allocation.length).toEqual 12
    expect(BulkCoopReport.columnOptions().packing_sheets.length).toEqual 5
    expect(BulkCoopReport.columnOptions().customer_payments.length).toEqual 6
