angular.module("ofn.admin").filter "producer", ($filter) ->
  return (products, producerID) ->
    return products if producerID == "0"
    $filter('filter')( products, { producer_id: producerID }, true )