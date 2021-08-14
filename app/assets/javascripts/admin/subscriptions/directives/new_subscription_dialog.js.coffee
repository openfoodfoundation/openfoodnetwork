angular.module("admin.subscriptions").directive 'newSubscriptionDialog', ($rootScope, $compile, $window, $templateCache, DialogDefaults, shops) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    scope.submitted = false
    scope.shops = shops
    scope.shop_id = null

    scope.newSubscription = ->
      scope.new_subscription_form.$setPristine()
      scope.submitted = true
      if scope.shop_id?
        $window.location.href = "/admin/subscriptions/new?subscription[shop_id]=#{scope.shop_id}"
      return

    # Compile modal template
    template = $compile($templateCache.get('admin/new_subscription_dialog.html'))(scope)

    # Set Dialog options
    template.dialog(DialogDefaults)

    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      if shops.length == 1
        scope.shop_id = shops[0].id
        scope.newSubscription()
      else
        template.dialog('open')
        $rootScope.$evalAsync()
