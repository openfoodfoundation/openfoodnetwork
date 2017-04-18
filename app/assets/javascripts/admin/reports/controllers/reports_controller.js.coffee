angular.module("admin.reports").controller 'ReportsCtrl', ($scope, $location) ->
  $scope.loading = false
  $scope.loadAttempted = false

  $scope.download = ($event, type, visibility = 'all') ->
    $event.stopPropagation()
    $event.preventDefault()
    if type == 'csv'
      $scope.gridApi.exporter.csvExport(visibility, visibility)
    else
      $scope.gridApi.exporter.pdfExport(visibility, visibility)

  $scope.reload = ->
    $scope.loading = false
    $scope.loadAttempted = false
    $scope.gridOptions.columnDefs = $scope.$eval('columnOptions.' + $scope.q.report_type)
    $location.search('report_type', $scope.q.report_type)
    $scope.gridOptions.data = new Array()
    $scope.gridApi.grid.refresh()
