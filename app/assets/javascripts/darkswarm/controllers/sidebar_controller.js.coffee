window.SidebarCtrl = Darkswarm.controller "SidebarCtrl", ($scope, $location) ->
  $scope.active = ->
    $location.hash() == "sidebar"
