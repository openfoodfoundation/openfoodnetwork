Darkswarm.factory 'Tabsets', ->
  new class Tabsets
    tabsets: []

    register: (ctrl, id, selected=null) ->
      if ctrl? && id?
        @tabsets.push { ctrl: ctrl, id: id, selected: selected }
        ctrl.select(selected) if selected?

    toggle: (id, name, state=null) ->
      tabset = @findTabsetByObject(id)
      if tabset.selected == name
        @select(tabset, null) unless state == "open"
      else
        @select(tabset, name) unless state == "closed"

    select: (tabset, name) ->
      tabset.selected = name
      tabset.ctrl.select(name)

    findTabsetByObject: (id) ->
      (tabset for tabset in @tabsets when tabset.id == id)[0]
