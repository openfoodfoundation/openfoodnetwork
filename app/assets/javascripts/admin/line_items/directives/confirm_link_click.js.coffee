# Used on a link to prevent link clicks unless a callback returns true (probably asking for user confirmation)
angular.module("admin.lineItems").directive "confirmLinkClick", ->
  restrict: "A"
  scope:
    confirmLinkClick: "&"
  link: (scope, element, attrs) ->
    element.bind "click", (event) ->
      unless scope.confirmLinkClick()
        event.preventDefault()
