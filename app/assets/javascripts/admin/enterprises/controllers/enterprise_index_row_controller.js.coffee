angular.module("admin.enterprises").controller "EnterpriseIndexRowCtrl", ($scope) ->
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
    $scope.producerError = ($scope.producer == "Choose")
    $scope.packageError = ($scope.package == "Choose")


  $scope.updateRowText()

  $scope.$on "enterprise:updated", ->
    $scope.updateRowText()
