angular.module("admin.side_menu")
  .factory "SideMenu", ->
    new class SideMenu
      items: []
      selected: null

      setItems: (items) =>
        @items = items

      select: (index) =>
        @selected.selected = false if @selected
        @selected = @items[index]
        @selected.selected = true


