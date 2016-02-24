describe "PanelRow directive", ->
  Panels = null
  element = null
  directiveScope = null

  beforeEach ->
    module 'admin.indexUtils'

  beforeEach inject ($rootScope, $compile, $injector, $templateCache, _Panels_) ->
    Panels = _Panels_
    $templateCache.put 'admin/panel.html', '<span>{{ template }}</span>'
    # Declare the directive HTML.
    element = angular.element('<div class="panel-row" object="{id: \'12\'}" panels="{ panel1: \'template\'}"></div>')
    # Define the root scope.
    scope = $rootScope
    # Compile and digest the directive.
    $compile(element) scope
    scope.$digest()

    directiveScope = element.find('span').scope()
    return

  describe "initialisation", ->
    it "registers the scope with the panels service", ->
      expect(Panels.panels[12]).toEqual directiveScope

  describe "setting the selected panel", ->
    beforeEach ->
      directiveScope.setSelected('panel1')

    it 'updates the active template on the scope', ->
      expect(element.find('span').html()).toEqual "admin/panels/template.html"
      return
