angular.module("admin.indexUtils").factory 'Panels', ->
  new class Panels
    panels: []

    register: (ctrl, object, selected=null) ->
      if ctrl? && object?
        @panels.push { ctrl: ctrl, object: object, selected: selected }
        ctrl.select(selected) if selected?

    toggle: (object, name, state=null) ->
      panel = @findPanelByObject(object)
      if panel.selected == name
        @select(panel, null) unless state == "open"
      else
        @select(panel, name) unless state == "closed"

    select: (panel, name) ->
      panel.selected = name
      panel.ctrl.select(name)

    findPanelByObject: (object) ->
      (panel for panel in @panels when panel.object == object)[0]
