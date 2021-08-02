angular.module('Darkswarm').factory "Sidebar", ($location, Navigation)->
  new class Sidebar
    paths: ["/login", "/signup", "/forgot", "/account"] 

    active: -> 
      $location.path() in @paths

    toggle: ->
      if Navigation.path in @paths
        Navigation.navigate(Navigation.path)
      else
        Navigation.navigate(@paths[0])

