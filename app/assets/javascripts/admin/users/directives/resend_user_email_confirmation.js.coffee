angular.module("admin.users").directive "resendUserEmailConfirmation", ($http) ->
  template: "{{ 'js.admin.resend_user_email_confirmation.' + status | t }}"
  scope:
    email: "@resendUserEmailConfirmation"
  link: (scope, element, attrs) ->
    sent = false
    scope.status = "resend"

    element.bind "click", ->
      return if sent
      scope.status = "sending"
      $http.post("/user/spree_user/confirmation", {spree_user: {email: scope.email}}).success (data) ->
        sent = true
        element.addClass "action--disabled"
        scope.status = "done"
      .error (data) ->
        scope.status = "failed"
