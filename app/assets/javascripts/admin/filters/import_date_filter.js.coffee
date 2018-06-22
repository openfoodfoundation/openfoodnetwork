angular.module("ofn.admin").filter "importDate", ($filter) ->
  return (products, importDate) ->
    return products if importDate == "0"
    $filter('filter')( products, { import_date: importDate } )
