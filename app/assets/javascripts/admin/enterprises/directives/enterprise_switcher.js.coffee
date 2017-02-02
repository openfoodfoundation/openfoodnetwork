angular.module('admin.enterprises').directive 'enterpriseSwitcher', (NavigationCheck) ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, element, attr, ngModel) ->
    initial = element[0].getAttribute('data-initial')

    element.on 'change', ->
      if not NavigationCheck.confirmLeave()
        # Reset the current dropdown selection if staying on page
        ngModel.$setViewValue initial
        ngModel.$render()
        element.select2 'val', initial
        return

      NavigationCheck.clear() # Don't ask twice if leaving
      window.location = element[0].querySelector('option[selected]').getAttribute('data-url')
