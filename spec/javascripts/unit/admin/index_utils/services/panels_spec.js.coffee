describe "Panels service", ->
  Panels = null

  beforeEach ->
    module 'admin.indexUtils'

    inject (_Panels_) ->
      Panels = _Panels_

  describe "registering panels", ->
    it "adds the panel provided scope to @panelsm indexed by the provided id", ->
      Panels.register(23, { some: 'scope'} )
      expect(Panels.panels[23]).toEqual { some: 'scope' }

    it "ignores the input if id or scope are null", ->
      Panels.register(null, { some: 'scope'} )
      Panels.register(23, null)
      expect(Panels.panels).toEqual { }

  describe "toggling a panel", ->
    scopeMock = null

    beforeEach ->
      scopeMock =
        open: jasmine.createSpy('open')
        close: jasmine.createSpy('close')
        setSelected: jasmine.createSpy('setSelected')
      Panels.panels = { '12':  scopeMock }

    describe "when no panel is currently selected", ->
      beforeEach ->
        scopeMock.getSelected = jasmine.createSpy('getSelected').andReturn(null)
        Panels.toggle(12, 'panel_name')

      it "calls #open on the scope", ->
        expect(scopeMock.open).toHaveBeenCalledWith('panel_name')

    describe "when #toggle is called for the currently selected panel", ->
      beforeEach ->
        scopeMock.getSelected = jasmine.createSpy('getSelected').andReturn('panel_name')
        Panels.toggle(12, 'panel_name')

      it "calls #close on the scope", ->
        expect(scopeMock.close).toHaveBeenCalled()

    describe "when #toggle is called for a different panel", ->
      beforeEach ->
        scopeMock.getSelected = jasmine.createSpy('getSelected').andReturn('some_other_panel_name')
        Panels.toggle(12, 'panel_name')

      it "calls #setSelected on the scope", ->
        expect(scopeMock.setSelected).toHaveBeenCalledWith('panel_name')
