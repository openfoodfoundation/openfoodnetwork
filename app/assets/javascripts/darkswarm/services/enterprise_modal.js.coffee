angular.module('Darkswarm').factory "EnterpriseModal", ($modal, $rootScope, $http)->
  # Build a modal popup for an enterprise.
  new class EnterpriseModal
    open: (enterprise)->
      return if enterprise.visible == 'hidden'
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.embedded_layout = window.location.search.indexOf("embedded_shopfront=true") != -1

      $http.get("/api/v0/shops/" + enterprise.id).then (response) ->
        scope.enterprise = response.data
        $modal.open(templateUrl: "enterprise_modal.html", scope: scope)
      .catch (response) ->
        console.error(response.data)
