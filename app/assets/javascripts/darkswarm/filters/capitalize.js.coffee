angular.module('Darkswarm').filter "capitalize", ->
  # Convert to basic sentence case.
  (input, scope) ->
    input = input.toLowerCase() if input?
    input.substring(0, 1).toUpperCase() + input.substring(1)
