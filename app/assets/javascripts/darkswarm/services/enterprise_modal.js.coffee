Darkswarm.factory "EnterpriseModal", ($modal, $rootScope)->
  # Build a modal popup for an enterprise.
  new class EnterpriseModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.embedded_layout = window.location.search.indexOf("embedded_shopfront=true") != -1

      scope.enterprise = enterprise
      $modal.open(templateUrl: "enterprise_modal.html", scope: scope)
