angular.module("admin.indexUtils").factory 'Columns', ($rootScope) ->
  new class Columns
    columns: {}
    visibleCount: 0

    setColumns: (columns) =>
      @columns = {}
      @columns[name] = column for name, column of columns
      @calculateVisibleCount()
      @columns

    toggleColumn: (column) =>
      column.visible = !column.visible
      @calculateVisibleCount()

    calculateVisibleCount: =>
      @visibleCount = (column for name, column of @columns when column.visible).length
      $rootScope.$broadcast "columnCount:changed", @visibleCount
