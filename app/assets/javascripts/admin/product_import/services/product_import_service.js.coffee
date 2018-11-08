angular.module("admin.productImport").factory "ProductImportService", ($rootScope) ->
  new class ProductImportService
    enterprises: {}
    resetTotal: 0
    settings: {}

    updateResetAbsent: (enterpriseId, resetCount, resetAbsent) ->
      if resetAbsent
        @enterprises[enterpriseId] = resetCount
        @resetTotal += resetCount
      else
        @enterprises[enterpriseId] = null
        @resetTotal -= resetCount

      $rootScope.resetTotal = @resetTotal

    updateSettings: (updated) ->
      angular.merge(@settings, updated)

    getSettings: () ->
      @settings