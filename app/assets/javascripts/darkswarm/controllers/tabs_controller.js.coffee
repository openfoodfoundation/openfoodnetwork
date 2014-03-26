Darkswarm.controller "TabsCtrl", ($scope, $rootScope, $location) ->
  $scope.active = (tab)->
    $location.path() == tab

  $scope.tabs = ["contact", "about", "groups", "producers"]
  for tab in $scope.tabs 
    $scope[tab] =
      active: false #$scope.active("/" + tab)
      path: "/" + tab 

  $scope.$watch ->
    $location.path() 
  , (path)->
    for tab in $scope.tabs
      $scope[tab].active = $scope.active($scope[tab].path) 

  #$scope.select = (tab)->
    #$location.path tab.path
    #
    #
    
# directive -> ng-click -> scope method (not isolated) -> toggle active | change location
# watch active expression -> change tab appearance

#select = ->
  #$location.path(tab.path)

#active expression:
  #"$location.path() == tab.path"


# directive -> ng-click -> set active (on isolated scope)
# ng-class -> change tab appearance
# two-way binding active attr <-> tab.active

# directive attr (select) -> scope.selectExpression
# scope.select -> $parse ...
#
# in Directive
# scope.select = $parse(attrs.select)
# $scope.select($scope)
#
# 1: remove reverse binding on tab.active
# 2: put $parse(attrs.select) onto tab
# 3: override TabsetController/select to run tab.select() against original tab.$parent
