angular.module("admin.utils").directive "datepicker", ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
      flatpickr(element,  Object.assign({},
                          window.FLATPICKR_DATE_DEFAULT, {
                          onOpen: (selectedDates, dateStr, instance) ->
                            instance.setDate(ngModel.$modelValue)
                          }));
