angular.module("admin.indexUtils").factory 'SortOptions', ->
  new class SortOptions
    predicate: ""
    reverse: true

    getSortingExpr: () ->
      sortingExpr = this.predicate + ' desc' if this.reverse
      sortingExpr = this.predicate + ' asc' if !this.reverse
      sortingExpr

    toggle: (predicate) ->
      @reverse = (@predicate == predicate) && !@reverse
      @predicate = predicate
