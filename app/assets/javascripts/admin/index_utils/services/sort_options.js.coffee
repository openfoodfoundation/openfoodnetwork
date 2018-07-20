angular.module("admin.indexUtils").factory 'SortOptions', ->
  new class SortOptions
    predicate: ""
    reverse: true

    toggle: (predicate) ->
      @reverse = (@predicate == predicate) && !@reverse
      @predicate = predicate
