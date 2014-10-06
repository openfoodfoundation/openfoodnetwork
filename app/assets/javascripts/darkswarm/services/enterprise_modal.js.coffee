Darkswarm.factory "EnterpriseModal", ($modal, $rootScope)->
  # Build a modal popup for an enterprise.
  new class EnterpriseModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise

      scope.enterprise = enterprise
      $modal.open(templateUrl: "enterprise_modal.html", scope: scope)
