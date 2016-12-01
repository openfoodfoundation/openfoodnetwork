angular.module("admin.indexUtils").factory 'Panels', ->
  new class Panels
    all: []

    register: (ctrl, object, selected=null) ->
      if ctrl? && object?
        existing = @panelFor(object)
        newPanel = { ctrl: ctrl, object: object, selected: selected }
        if existing then angular.extend(existing, newPanel) else @all.push(newPanel)
        ctrl.select(selected) if selected?

    toggle: (object, name, state=null) ->
      panel = @panelFor(object)
      if panel.selected == name
        @select(panel, null) unless state == "open"
      else
        @select(panel, name) unless state == "closed"

    select: (panel, name) ->
      panel.selected = name
      panel.ctrl.select(name)

    panelFor: (object) ->
      (@all.filter (panel) -> panel.object == object)[0]
