describe "ColumnsCtrl", ->
  ctrl = null
  scope = null
  Columns = null

  beforeEach ->
    Columns = { columns: { name: { visible: true} } }

    module('admin.indexUtils')
    inject ($controller, $rootScope) ->
      scope = $rootScope
      ctrl = $controller 'ColumnsCtrl', {$scope: scope, Columns: Columns}

  it "initialises data", ->
    expect(scope.columns).toEqual Columns.columns
