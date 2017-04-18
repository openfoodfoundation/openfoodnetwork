describe 'ReportsCtrl', ->
  ctrl = null
  scope = {}
  controller = {}
  location = null
  gridOptions = {}

  beforeEach ->
    module('admin.reports')
    inject ($controller, $rootScope, _$location_) ->
      scope = $rootScope.$new()
      scope.gridOptions = {columnDefs: null, data: [1]}
      scope.columnOptions = {report: {a: 'b'}}
      scope.gridApi = {grid: {refresh: ->}}
      scope.q = {report_type: 'report'}
      location = _$location_
      ctrl = $controller 'ReportsCtrl', {$scope: scope, $location: location}

  it 'init ui-grid loading flags should be false', ->
    expect(scope.loading).toBe false
    expect(scope.loadAttempted).toBe false

  describe '#reload', ->
    it 'changes ui-grid table definintions', ->
      spyOn(scope.gridApi.grid, "refresh").and.callThrough()

      scope.reload()

      expect(scope.loading).toBe false
      expect(scope.loadAttempted).toBe false
      expect(scope.gridOptions.columnDefs).toEqual {a: 'b'}
      expect(scope.gridOptions.data).toEqual []
      expect(scope.gridApi.grid.refresh).toHaveBeenCalled()


  describe '#download', ->
    event = {
      stopPropagation: ->
      preventDefault: ->
    }

    beforeEach ->
      scope.gridApi.exporter = {
        pdfExport: ->
        csvExport: ->
      }

    it 'gives PDF file', ->
      spyOn(scope.gridApi.exporter, "pdfExport").and.callThrough()
      scope.download(event)
      expect(scope.gridApi.exporter.pdfExport).toHaveBeenCalled()

    it 'gives CSV file', ->
      spyOn(scope.gridApi.exporter, "csvExport").and.callThrough()
      scope.download(event, 'csv')
      expect(scope.gridApi.exporter.csvExport).toHaveBeenCalled()
