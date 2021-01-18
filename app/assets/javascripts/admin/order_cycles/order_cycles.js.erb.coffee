angular.module('admin.orderCycles', ['ngTagsInput', 'admin.indexUtils', 'admin.enterprises'])
  .directive 'datetimepicker', ($timeout, $parse) ->
    require: "ngModel"
    link: (scope, element, attrs, ngModel) ->
      $timeout ->
        flatpickr(element,  Object.assign({},
                            window.FLATPICKR_DATETIME_DEFAULT, {
                            onOpen: (selectedDates, dateStr, instance) ->
                              instance.setDate(ngModel.$modelValue)
                            }));

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
