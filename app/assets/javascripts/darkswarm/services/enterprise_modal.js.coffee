Darkswarm.factory "EnterpriseModal", ($modal, $rootScope)->
  new class EnterpriseModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise

      scope.enterprise = enterprise
      $modal.open(templateUrl: "enterprise_modal.html", scope: scope)
