angular.module("admin.indexUtils").factory 'Views', ($rootScope) ->
  new class Views
    views: {}
    currentView: null

    setViews: (views) =>
      @views = {}
      for key, view of views
        @views[key] = view
        @selectView(key) if view.visible
      @views

    selectView: (selectedKey) =>
      @currentView = @views[selectedKey]
      for key, view of @views
        view.visible = (key == selectedKey)
