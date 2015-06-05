angular.module("admin.indexUtils").factory 'Panels', ->
  new class Panels
    panels: {}

    register: (id, scope) ->
      if id? && scope?
        @panels[id] = scope

    toggle: (id, name) ->
      scope = @panels[id]
      selected = scope.getSelected()
      switch selected
        when name
          scope.close()
        when null
          scope.open(name)
        else
          scope.setSelected(name)
