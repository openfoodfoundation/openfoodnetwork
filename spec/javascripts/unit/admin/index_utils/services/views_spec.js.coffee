describe "Views service", ->
  Views = null

  beforeEach ->
    module 'admin.indexUtils'

    inject (_Views_) ->
      Views = _Views_

  describe "setting views", ->
    beforeEach ->
      spyOn(Views, "selectView").and.callThrough()
      Views.setViews
        view1: { name: 'View1', visible: true }
        view2: { name: 'View2', visible: false }
        view3: { name: 'View3', visible: true }

    it "sets resets @views and copies each view of the provided object across", ->
      expect(Object.keys(Views.views)).toEqual ['view1', 'view2', 'view3']

    it "calls selectView if visible is true", ->
      expect(Views.selectView).toHaveBeenCalledWith('view1')
      expect(Views.selectView).not.toHaveBeenCalledWith('view2');
      expect(Views.selectView).toHaveBeenCalledWith('view3')
      expect(view.visible for key, view of Views.views).toEqual [false, false, true]

  describe "selecting a view", ->
    beforeEach ->
      Views.currentView = "some View"
      Views.views = { view7: { name: 'View7', visible: false } }
      Views.selectView('view7')

    it "sets the currentView", ->
      expect(Views.currentView.name).toEqual 'View7'

    it "switches the visibility of the given view", ->
      expect(Views.currentView).toEqual { name: 'View7', visible: true }
