angular.module("admin.side_menu")
  .factory "SideMenu", ($location) ->
    new class SideMenu
      items: []
      selected: null
      didSelect: false

      # Checks for path and uses it to set the view
      # If no path, loads first view
      init: =>
        path = $location.path()?.match(/^\/\w+$/)?[0]
        index = @getIndexFromPath(path)
        @select(index)

      locationDidChange: (path) =>
        if !@didSelect # do not reselect if it has been already done
          index = @getIndexFromPath(path)
          @select(index)
          # reset the focus on active element to avoid links on side menu to be focused
          document.activeElement.blur()
        @didSelect = false

      setItems: (items) =>
        @items = items
        item.visible = true for item in @items

      select: (index) =>
        if index < @items.length
          @selected.selected = false if @selected
          @selected = @items[index]
          @selected.selected = true
          @didSelect = true
          $location.path(@selected.name)          

      getIndexFromPath: (path) =>
        index = if path
          name = path[1..]
          @items.indexOf(@find_by_name(name))
        else
          0

      find_by_name: (name) =>
        for item in @items when item.name is name
          return item
        null
