angular.module('admin.enterprises').directive 'enterpriseSwitcher',
['$window','FormState','NavigationCheck', ($window, FormState, NavigationCheck) ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, element, attr, ngModel) ->
    initial = element[0].getAttribute('data-initial')
    confirm_message = t('admin.unsaved_confirm_leave')

    element.on 'change', ->
      if FormState.isDirty
        #Confirm if form is dirty
        if !confirm(confirm_message)
          #Reset the current dropdown selection if staying on page
          ngModel.$setViewValue initial
          ngModel.$render()
          element.select2 'val', initial
          return

      NavigationCheck.clear() #Don't ask twice if leaving
      window.location = element[0].querySelector('option[selected]').getAttribute('data-url')

]