angular.module("admin.indexUtils").factory 'SortOptions', ->
  new class SortOptions
    predicate: ""
    reverse: true

    toggle: (predicate) ->
      @predicate = predicate
      @reverse = !@reverse
