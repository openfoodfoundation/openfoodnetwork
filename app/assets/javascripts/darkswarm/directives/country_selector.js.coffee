Darkswarm.directive "countrySelector", () ->
  restrict: "A"
  require: 'ngModel'
  link: (scope, elem, attrs)->
    defaultCountry = elem[0].getAttribute('data-default')
    options = elem[0].querySelectorAll('option')

    #Set default country on country dropdown
    angular.forEach options, (value, key) =>
      if value.label == defaultCountry
        scope.enterprise.country = scope.countries[key]
