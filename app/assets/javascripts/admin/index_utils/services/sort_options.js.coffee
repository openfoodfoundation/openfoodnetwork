angular.module("admin.indexUtils").factory 'SortOptions', ->
  new class SortOptions
    predicate: ""
    reverse: true

    getSortingExpr: (options) ->
      defaultDirection = if (options && options.defaultDirection) then options.defaultDirection else "desc"
      reverseDirection = if defaultDirection == "desc" then "asc" else "desc"
      sortingExpr = this.predicate + ' ' + defaultDirection if this.reverse
      sortingExpr = this.predicate + ' ' + reverseDirection if !this.reverse
      sortingExpr

    toggle: (predicate) ->
      @reverse = (@predicate == predicate) && !@reverse
      @predicate = predicate
