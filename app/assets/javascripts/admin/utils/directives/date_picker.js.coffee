angular.module("admin.utils").directive "datepicker", ($window, $timeout) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    $timeout ->
      flatpickr(element,  Object.assign(
                            {},
                            $window.FLATPICKR_DATE_DEFAULT, {
                            onOpen: (selectedDates, dateStr, instance) ->
                              instance.setDate(ngModel.$modelValue)
                            }
                          ));
