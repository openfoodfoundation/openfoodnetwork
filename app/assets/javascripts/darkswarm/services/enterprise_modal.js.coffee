angular.module('Darkswarm').factory "EnterpriseModal", ($modal, $rootScope, $http)->
  # Build a modal popup for an enterprise.
  new class EnterpriseModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.embedded_layout = window.location.search.indexOf("embedded_shopfront=true") != -1

      $http.get("/api/v0/shops/" + enterprise.id).success (data) ->
        scope.enterprise = data
        $modal.open(templateUrl: "enterprise_modal.html", scope: scope)
      .error (data) ->
        console.error(data)
