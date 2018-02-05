describe "Panels service", ->
  Panels = null

  beforeEach ->
    module 'admin.indexUtils'

    inject (_Panels_) ->
      Panels = _Panels_

  describe "registering panels", ->
    ctrl1 = ctrl2 = null
    beforeEach ->
      ctrl1 = jasmine.createSpyObj('ctrl', ['select'])
      ctrl2 = jasmine.createSpyObj('ctrl', ['select'])

    it "adds the panels controller, object and selection to @byObjectID", ->
      Panels.register(ctrl1, { name: "obj1"}, "panel1")
      Panels.register(ctrl2, { name: "obj2"})
      expect(Panels.all[0]).toEqual { ctrl: ctrl1, object: { name: "obj1"}, selected: "panel1" }
      expect(Panels.all[1]).toEqual { ctrl: ctrl2, object: { name: "obj2"}, selected: null }

    it "call select on the controller if a selection is provided", ->
      Panels.register(ctrl1, { name: "obj1"}, "panel1")
      Panels.register(ctrl2, { name: "obj2"})
      expect(ctrl1.select.calls.count()).toEqual 1
      expect(ctrl2.select.calls.count()).toEqual 0

    it "ignores the input if ctrl, object are null", ->
      Panels.register(ctrl1, null)
      Panels.register(null, { name: "obj2"})
      expect(Panels.all.length).toEqual 0

  describe "toggling a panel", ->
    panelMock = ctrlMock = objMock = null

    beforeEach ->
      objMock = {some: "object"}
      ctrlMock = jasmine.createSpyObj('ctrl', ['select'])
      panelMock = { ctrl: ctrlMock, object: objMock }
      Panels.all = [panelMock]

    describe "when no panel is currently selected", ->
      beforeEach ->
        panelMock.selected = null

      describe "when no state is provided", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name')

        it "selects the named panel", ->
          expect(panelMock.selected).toEqual 'panel_name'
          expect(ctrlMock.select).toHaveBeenCalledWith('panel_name')

      describe "when the state given is 'open'", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name', "open")

        it "selects the named panel", ->
          expect(panelMock.selected).toEqual 'panel_name'
          expect(ctrlMock.select).toHaveBeenCalledWith('panel_name')

      describe "when the state given is 'closed'", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name', "closed")

        it "does not select the named panel", ->
          expect(panelMock.selected).toEqual null
          expect(ctrlMock.select).not.toHaveBeenCalledWith('panel_name')

    describe "when the currently selected panel matches the named panel", ->
      beforeEach ->
        panelMock.selected = 'panel_name'

      describe "when no state is provided", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name')

        it "de-selects the named panel", ->
          expect(panelMock.selected).toEqual null
          expect(ctrlMock.select).toHaveBeenCalledWith(null)

      describe "when the state given is 'open'", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name', "open")

        it "keeps the the named panel selected, but does not call select on the controller", ->
          expect(panelMock.selected).toEqual 'panel_name'
          expect(ctrlMock.select).not.toHaveBeenCalledWith('panel_name')

      describe "when the state given is 'closed'", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name', "closed")

        it "de-selects the named panel", ->
          expect(panelMock.selected).toEqual null
          expect(ctrlMock.select).not.toHaveBeenCalledWith('panel_name')

    describe "when the currently selected panel does not match the requested panel", ->
      beforeEach ->
        panelMock.selected = 'some_other_panel'

      describe "when no state is provided", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name')

        it "selects the named panel", ->
          expect(panelMock.selected).toEqual 'panel_name'
          expect(ctrlMock.select).toHaveBeenCalledWith('panel_name')

      describe "when the state given is 'open'", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name', "open")

        it "selects the named panel", ->
          expect(panelMock.selected).toEqual 'panel_name'
          expect(ctrlMock.select).toHaveBeenCalledWith('panel_name')

      describe "when the state given is 'closed'", ->
        beforeEach -> Panels.toggle(objMock, 'panel_name', "closed")

        it "keeps the currently selected panel selected, ie. does nothing", ->
          expect(panelMock.selected).toEqual "some_other_panel"
          expect(ctrlMock.select).not.toHaveBeenCalledWith('panel_name')
          expect(ctrlMock.select).not.toHaveBeenCalledWith('some_other_panel')
