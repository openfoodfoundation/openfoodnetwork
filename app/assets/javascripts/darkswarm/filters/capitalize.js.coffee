Darkswarm.filter "capitalize", ->
  (input, scope) ->
    input = input.toLowerCase()  if input?
    input.substring(0, 1).toUpperCase() + input.substring(1)
