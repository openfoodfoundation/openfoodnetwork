angular.module("admin.indexUtils").directive "panelToggleRow", (Panels) ->
  restrict: "C"
  scope:
    object: "="
    selected: "@?"
  controller: ($scope) ->
    panelToggles = {}

    this.register = (name, element) ->
      panelToggles[name] = element
      panelToggles[name].addClass("selected") if $scope.selected == name
      $scope.selected == name

    this.select = (name) ->
      panelToggle.removeClass("selected") for panelName, panelToggle of panelToggles

      switch $scope.selected = Panels.toggle($scope.object.id, name)
        when null
          panelToggles[name].parent(".panel-toggle-row").removeClass("expanded")
        else
          panelToggles[$scope.selected].addClass("selected")
          panelToggles[$scope.selected].parent(".panel-toggle-row").addClass("expanded")

      $scope.selected == name

    this
  #
  # link: (scope, element, attrs) ->
  #   Panels.registerInitialSelection(scope.object.id, scope.selected)
