angular.module("admin.users").directive "resendUserEmailConfirmation", ($http) ->
  scope:
    email: "@resendUserEmailConfirmation"
  link: (scope, element, attrs) ->
    sent = false
    text = element.text()
    sending = " " + t "js.admin.resend_user_email_confirmation.sending"
    done = " " + t "js.admin.resend_user_email_confirmation.done"
    failed = " " + t "js.admin.resend_user_email_confirmation.failed"

    element.bind "click", ->
      return if sent
      element.text(text + sending)
      $http.post("/user/spree_user/confirmation", {spree_user: {email: scope.email}}).success (data) ->
        sent = true
        element.addClass "action--disabled"
        element.text text + done
      .error (data) ->
        element.text text + failed
