Darkswarm.factory "EnterpriseListModal", ($modal, $rootScope, $http, EnterpriseModal)->
  # Build a modal popup for an enterprise.
  new class EnterpriseListModal
    open: (enterprises)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.embedded_layout = window.location.search.indexOf("embedded_shopfront=true") != -1
      scope.enterprises = enterprises
      scope.openModal = EnterpriseModal.open
      if Object.keys(enterprises).length > 1
        $modal.open(templateUrl: "enterprise_list_modal.html", scope: scope)
      else
        EnterpriseModal.open enterprises[Object.keys(enterprises)[0]]
