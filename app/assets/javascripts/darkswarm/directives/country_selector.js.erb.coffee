Darkswarm.directive "countrySelector", (RegistrationService) ->
  restrict: "A"
  require: 'ngModel'
  link: (scope, elem, attrs)->
    defaultCountry = "<%= Spree::Country.find_by_id(Spree::Config[:default_country_id]) %>"
    options = elem[0].querySelectorAll('option')

    #Set default country on country dropdown
    angular.forEach options, (value, key) =>
      if value.label == defaultCountry
        scope.enterprise.country = scope.countries[key]
