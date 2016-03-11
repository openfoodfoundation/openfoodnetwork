angular.module("admin.enterpriseFees").directive 'ngBindHtmlUnsafeCompiled', ($compile) ->
  (scope, element, attrs) ->
    scope.$watch attrs.ngBindHtmlUnsafeCompiled, (value) ->
      element.html $compile(value)(scope)
      return
    return
