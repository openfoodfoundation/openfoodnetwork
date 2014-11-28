angular.module("admin.side_menu")
  .factory "SideMenu", ->
    new class SideMenu
      items: []
      selected: null

      setItems: (items) =>
        @items = items
        item.visible = true for item in @items

      select: (index) =>
        if index < @items.length
          @selected.selected = false if @selected
          @selected = @items[index]
          @selected.selected = true

      find_by_name: (name) =>
        for item in @items when item.name is name
          return item
        null

      hide_item_by_name: (name) =>
        item = @find_by_name(name)
        item.visible = false if item

      show_item_by_name: (name) =>
        item = @find_by_name(name)
        item.visible = true if item
