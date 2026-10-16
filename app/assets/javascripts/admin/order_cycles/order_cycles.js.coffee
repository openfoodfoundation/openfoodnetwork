angular.module('admin.orderCycles', ['ngTagsInput', 'admin.indexUtils', 'admin.enterprises'])
  .directive 'ofnSyncDistributions', ->
    (scope, element, attrs) ->
      element.bind 'change', ->
        checked = $(this).is(':checked')
        scope.$apply ->
          if checked
            scope.addDistributionOfVariant(attrs.ofnSyncDistributions)
          else
            scope.removeDistributionOfVariant(attrs.ofnSyncDistributions)
