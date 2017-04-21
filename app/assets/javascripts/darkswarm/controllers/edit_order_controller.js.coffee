Darkswarm.controller "EditOrderCtrl", ($scope, $resource, Cart) ->

  $scope.deleteLineItem = (id) ->
    params = {id: id}
    success = (response) ->
      $(".line-item-" + id).remove()
      Cart.removeFinalisedLineItem(id)
    fail = (error) ->
      console.log error

    $resource("/line_items/:id").delete(params, success, fail)
