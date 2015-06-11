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
        switch $scope.enterprise.sells
          when "none"
            "Profile"
          else
            "Hub"
