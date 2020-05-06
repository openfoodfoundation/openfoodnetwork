Darkswarm.factory "EnterpriseModal", ($modal, $rootScope, $http, EnterpriseBox)->
  # Build a modal popup for an enterprise.
  new class EnterpriseModal
    open: (enterprises)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.embedded_layout = window.location.search.indexOf("embedded_shopfront=true") != -1
      scope.enterprises = enterprises
      scope.EnterpriseBox = EnterpriseBox
      len = Object.keys(enterprises).length
      if len > 1
        $modal.open(templateUrl: "enterprise_modal.html", scope: scope)
      else
        EnterpriseBox.open enterprises[Object.keys(enterprises)[0]]
