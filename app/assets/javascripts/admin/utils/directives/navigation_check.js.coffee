angular.module("admin.utils").directive "navCheckCallback", (NavigationCheck)->
  restrict: 'A'
  scope:
    navCheckCallback: '&'
  link: (scope,element,attributes) ->
    # Provide a callback, otherwise this default will be used:
    callback = scope.navCheckCallback()
    callback ||= ->
      "You will lose any unsaved work!"
    NavigationCheck.register(callback)
