describe "PanelRow directive", ->
  Panels = null
  element = null
  panelScope = null
  rowScope = null

  beforeEach ->
    module 'admin.indexUtils'
    module ($provide) ->
      $provide.value 'columns', []
      null

  beforeEach inject ($rootScope, $compile, $injector, $templateCache, _Panels_) ->
    Panels = _Panels_
    $templateCache.put 'admin/panel.html', '<span>{{ template }}</span>'
    # Declare the directive HTML.
    element = angular.element('<table><tbody class="panel-toggle-row"><tr class="panel-row" object="{id: \'12\'}" panels="{ panel1: \'template\'}"></tr></tbody><table>')
    # Define the root scope.
    scope = $rootScope
    # Compile and digest the directive.
    $compile(element) scope
    scope.$digest()

    rowScope = element.find('tbody').isolateScope()
    panelScope = element.find('tr').isolateScope()
    return

  describe "initialisation", ->
    it "registers a listener on the row scope", ->
      expect(rowScope.$$listeners["selection:changed"].length).toEqual 1

  describe "when a select event is triggered on the row scope", ->
    beforeEach ->
      rowScope.$broadcast('selection:changed', 'panel1')

    it 'updates the active template on the scope', ->
      panelScope.$digest()
      expect(panelScope.template).toEqual "admin/panels/template.html"
      expect(element.find('span').html()).toEqual "admin/panels/template.html"
      return
