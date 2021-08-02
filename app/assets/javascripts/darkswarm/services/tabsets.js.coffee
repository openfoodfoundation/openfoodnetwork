angular.module('Darkswarm').factory 'Tabsets', ->
  new class Tabsets
    tabsets: []

    register: (ctrl, id, selected=null) ->
      if ctrl? && id?
        @tabsets.push { ctrl: ctrl, id: id, selected: selected }
        ctrl.select(selected) if selected?

    toggle: (id, name) ->
      tabset = @findTabsetByObject(id)
      if tabset.selected != name
        @select(tabset, name)

    select: (tabset, name) ->
      tabset.selected = name
      tabset.ctrl.select(name)

    findTabsetByObject: (id) ->
      (tabset for tabset in @tabsets when tabset.id == id)[0]
