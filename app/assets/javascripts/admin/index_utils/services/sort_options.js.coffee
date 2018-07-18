angular.module("admin.indexUtils").factory 'SortOptions', ->
  new class SortOptions
    predicate: ""
    reverse: true
