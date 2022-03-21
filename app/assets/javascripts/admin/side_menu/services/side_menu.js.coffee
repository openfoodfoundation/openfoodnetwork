angular.module("admin.side_menu")
  .factory "SideMenu", ($location) ->
    new class SideMenu
      items: []
      selected: null

      # Checks for path and uses it to set the view
      # If no path, loads first view
      init: =>
        path = $location.path()?.match(/^\/\w+$/)?[0]
        index = if path
          name = path[1..]
          @items.indexOf(@find_by_name(name))
        else
          0
        @select(index)

      setItems: (items) =>
        @items = items
        item.visible = true for item in @items

      select: (index) =>
        if index < @items.length
          @selected.selected = false if @selected
          @selected = @items[index]
          @selected.selected = true
          $location.path(@selected.name)

      find_by_name: (name) =>
        for item in @items when item.name is name
          return item
        null

      redirect_function: (elementID , href) =>
        window.addEventListener 'load', ->
          element = document.getElementById(elementID)
          if !element
            return
          element.addEventListener 'click', ->
            window.location.replace(href)
            return
          return

