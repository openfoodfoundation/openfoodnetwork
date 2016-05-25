describe "SideMenu service", ->
  SideMenu = null

  beforeEach ->
    module "admin.side_menu"

  beforeEach inject (_SideMenu_) ->
    SideMenu = _SideMenu_

  describe "setting items", ->
    it "sets the items", ->
      items = [ { name: "Name 1"}, { name: "Name 2"} ]
      SideMenu.setItems items
      expect(SideMenu.items[0]).toBe items[0]

    it "sets the the visible flag to true for each", ->
      items = [ { name: "Name 1"}, { name: "Name 2"} ]
      SideMenu.setItems items
      expect(items[0].visible).toBe true

  describe "selecting an item", ->
    describe "when no item has been selected", ->
      it "doesn't crash because of no selected item existing", ->
        SideMenu.items = [ { name: "Name 1"}, { name: "Name 2"} ]
        SideMenu.select(1)

      it "sets selected to the new item", ->
        SideMenu.items = [ { name: "Name 1"}, { name: "Name 2"} ]
        SideMenu.select(1)
        expect(SideMenu.find_by_name("Name 2")).toBe SideMenu.items[1]

      it "switches the selected value of the newly selected item to true", ->
        item1 = { name: "Name 1", selected: false }
        item2 = { name: "Name 2", selected: false }
        SideMenu.items = [ item1, item2 ]
        SideMenu.select(1)
        expect(item2.selected).toBe true

      it "doesn't crash if given an index greater than the length of items", ->
        SideMenu.items = [ { name: "Name 1"}, { name: "Name 2"} ]
        SideMenu.select(12)

    describe "when an item has been selected", ->
      item1 = item2 = null

      beforeEach ->
        item1 = { name: "Name 1", selected: true }
        item2 = { name: "Name 2", selected: false }
        SideMenu.selected = item1
        SideMenu.items = [ item1, item2 ]
        SideMenu.select(1)

      it "switches the selected value of the existing selected item to false", ->
        expect(item1.selected).toBe false

      it "switches the selected value of the newly selected item to true", ->
        expect(item2.selected).toBe true


  describe "finding by name", ->
    it "returns the element that matches", ->
      SideMenu.items = [ { name: "Name 1"}, { name: "Name 2"} ]
      expect(SideMenu.find_by_name("Name 2")).toBe SideMenu.items[1]

    it "returns one element even if two items are found", ->
      SideMenu.items = [ { name: "Name 1"}, { name: "Name 1"} ]
      expect(SideMenu.find_by_name("Name 1")).toBe SideMenu.items[0]

    it "returns null if no items are found", ->
      SideMenu.items = [ { name: "Name 1"}, { name: "Name 2"} ]
      expect(SideMenu.find_by_name("Name 3")).toBe null

  describe "hiding an item by name", ->
    it "sets visible to false on the response from find_by_name", ->
      mockItem = { visible: true }
      spyOn(SideMenu, 'find_by_name').and.returnValue mockItem
      SideMenu.hide_item_by_name()
      expect(mockItem.visible).toBe false

    it "doesn't crash if null is returned from find_by_name", ->
      spyOn(SideMenu, 'find_by_name').and.returnValue null
      SideMenu.hide_item_by_name()

  describe "showing an item by name", ->
    it "sets visible to false on the response from find_by_name", ->
      mockItem = { visible: false }
      spyOn(SideMenu, 'find_by_name').and.returnValue mockItem
      SideMenu.show_item_by_name()
      expect(mockItem.visible).toBe true

    it "doesn't crash if null is returned from find_by_name", ->
      spyOn(SideMenu, 'find_by_name').and.returnValue null
      SideMenu.show_item_by_name()
