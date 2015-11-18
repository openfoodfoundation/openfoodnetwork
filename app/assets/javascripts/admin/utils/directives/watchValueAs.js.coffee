angular.module("admin.utils").directive "watchValueAs", ->
  restrict: 'A'
  scope: {
    value: "=watchValueAs"
  }
  link: (scope, element, attrs) ->
    scope.value = element.val()

    element.on "change blur load", ->
      scope.$apply ->
        scope.value = element.val()
