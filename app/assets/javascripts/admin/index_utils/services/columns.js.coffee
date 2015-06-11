angular.module("admin.indexUtils").factory 'Columns', ->
  new class Columns
    columns: {}

    setColumns: (columns) ->
      @columns = {}
      @columns[name] = column for name, column of columns
      @columns
