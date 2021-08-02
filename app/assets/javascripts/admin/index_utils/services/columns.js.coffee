angular.module("admin.indexUtils").factory 'Columns', ($rootScope, $http, $injector) ->
  new class Columns
    savedColumns: {}
    columns: {}
    visibleCount: 0

    constructor: ->
      @columns = {}
      for column in @injectColumns()
        @columns[column.column_name] = column
        @savedColumns[column.column_name] = angular.copy(column)
      @calculateVisibleCount()

    injectColumns: ->
      if $injector.has('columns')
        $injector.get('columns')
      else
        []

    toggleColumn: (column) =>
      column.visible = !column.visible
      @calculateVisibleCount()

    calculateVisibleCount: =>
      @visibleCount = (column for name, column of @columns when column.visible).length
      $rootScope.$broadcast "columnCount:changed", @visibleCount

    preferencesSaved: =>
      angular.equals(@columns, @savedColumns)

    savePreferences: (action_name) =>
      $http
        method: "PUT"
        url: "/admin/column_preferences/bulk_update"
        data:
          action_name: action_name
          column_preferences: (preference for column_name, preference of @columns)
      .then (response) =>
        for column in response.data
          angular.extend(@columns[column.column_name], column)
          angular.extend(@savedColumns[column.column_name], column)
