Darkswarm.factory "MapModal", ($modal, $rootScope)->
  new class MapModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.enterprise = enterprise
      $modal.open(templateUrl: "map_modal.html", scope: scope)
