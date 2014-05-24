angular.module("ofn.admin").directive "ofnConfirmLinkPath", (ofnConfirmHandler) ->
  restrict: "A"
  scope:
    path: "@ofnConfirmLinkPath"
  link: (scope, element, attrs) ->
    element.click ofnConfirmHandler scope, ->
      window.location = scope.path