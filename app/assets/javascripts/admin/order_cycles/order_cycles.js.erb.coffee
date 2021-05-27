angular.module('admin.orderCycles', ['ngTagsInput', 'admin.indexUtils', 'admin.enterprises'])
  .directive 'datetimepicker', ($timeout, $parse) ->
    require: "ngModel"
    link: (scope, element, attrs, ngModel) ->
      $timeout ->
        fp = flatpickr(element,  Object.assign({},
                            window.FLATPICKR_DATETIME_DEFAULT, {
                            onOpen: (selectedDates, dateStr, instance) ->
                              instance.setDate(ngModel.$modelValue)
                              instance.input.dispatchEvent(new Event('focus', { bubbles: true }));
                            }));
        fp.minuteElement.addEventListener "keyup", (e) ->
          if !isNaN(event.target.value)
            fp.setDate(fp.selectedDates[0].setMinutes(e.target.value), true)
        fp.hourElement.addEventListener "keyup", (e) ->
          if !isNaN(event.target.value)
            fp.setDate(fp.selectedDates[0].setHours(e.target.value), true)            

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
