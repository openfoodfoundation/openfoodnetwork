angular.module("admin.indexUtils").factory 'Columns', ($rootScope, $http, columns) ->
  new class Columns
    columns: {}
    visibleCount: 0
    saving: false

    constructor: ->
      @columns = {}
      for column in columns
        @columns[column.column_name] = column
      @calculateVisibleCount()

    toggleColumn: (column) =>
      column.visible = !column.visible
      @calculateVisibleCount()

    calculateVisibleCount: =>
      @visibleCount = (column for name, column of @columns when column.visible).length
      $rootScope.$broadcast "columnCount:changed", @visibleCount

    savePreferences: (action_name) ->
      $http
        method: "PUT"
        url: "/admin/column_preferences/bulk_update"
        data:
          action_name: action_name
          column_preferences: (preference for column_name, preference of @columns)
