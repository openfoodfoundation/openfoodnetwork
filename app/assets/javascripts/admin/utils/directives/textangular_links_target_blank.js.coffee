angular.module("admin.utils").directive "textangularLinksTargetBlank", () ->
  restrict: 'CA'
  link: (scope, element, attrs) ->
    setTimeout ->
      element.find(".ta-editor").scope().defaultTagAttributes.a.target = '_blank'
    , 500
