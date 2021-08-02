angular.module('Darkswarm').controller "GroupsCtrl", ($scope, Groups, Search) ->
  $scope.Groups = Groups
  $scope.order = 'position'
  $scope.query = Search.search()

  $scope.$watch "query", (query)->
    Search.search query
