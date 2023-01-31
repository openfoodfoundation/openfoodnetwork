angular.module('admin.orderCycles', ['ngTagsInput', 'admin.indexUtils', 'admin.enterprises'])
  .directive 'ofnOnChange', ->
    (scope, element, attrs) ->
      element.bind 'change', ->
        scope.$apply(attrs.ofnOnChange)

  .directive 'ofnSyncDistributions', ->
    (scope, element, attrs) ->
      element.bind 'change', ->
        if !$(this).is(':checked')
          scope.$apply ->
            scope.removeDistributionOfVariant(attrs.ofnSyncDistributions)
