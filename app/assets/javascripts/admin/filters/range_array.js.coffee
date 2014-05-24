angular.module("ofn.admin").filter "rangeArray", ->
  return (input,start,end) ->
    input.push(i) for i in [start..end]
    input