Darkswarm.directive "submitCheckout", () ->
  restrict: "A"
  link: (scope, elm, attr)->
    elm.bind 'click', (ev)->
      ev.preventDefault()

      names = ["details", "billing", "shipping", "payment"]
      for name of names
        if not scope[name].$valid
          $scope.show name
      # else
      #   scope.purchase(ev)

