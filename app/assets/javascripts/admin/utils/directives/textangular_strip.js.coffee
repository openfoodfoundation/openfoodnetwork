angular.module("admin.utils").directive "textangularStrip", () ->
  restrict: 'CA'
  link: (scope, element, attrs) ->
    scope.stripFormatting = ($html) ->
      return String($html).replace(/<[^>]+>/gm, '')
