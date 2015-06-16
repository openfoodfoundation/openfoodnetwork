angular.module("admin.enterprises").controller "EnterpriseIndexRowCtrl", ($scope) ->
  $scope.statusText = ->
    issueCount = (issue for issue in $scope.enterprise.issues when !issue.resolved).length
    if issueCount > 0
      $scope.statusClass = "issue"
    else
      warningCount = (warning for warning in $scope.enterprise.warnings when !warning.resolved).length
      if warningCount > 0
        $scope.statusClass = "warning"
      else
        $scope.statusClass = "ok"


  $scope.producerText = ->
    switch $scope.enterprise.is_primary_producer
      when true
        "Producer"
      else
        "Non-Producer"

  $scope.packageText = ->
    switch $scope.enterprise.is_primary_producer
      when true
        switch $scope.enterprise.sells
          when "none"
            "Profile"
          when "own"
            "Shop"
          when "any"
            "Hub"
          else
            "Choose"
      else
        switch $scope.enterprise.sells
          when "none"
            "Profile"
          when "any"
            "Hub"
          else
            "Choose"

  $scope.updateRowText = ->
    $scope.producer = $scope.producerText()
    $scope.package = $scope.packageText()
    $scope.status = $scope.statusText()
    $scope.producerError = ($scope.producer == "Choose")
    $scope.packageError = ($scope.package == "Choose")


  $scope.updateRowText()

  $scope.$on "enterprise:updated", ->
    $scope.updateRowText()
