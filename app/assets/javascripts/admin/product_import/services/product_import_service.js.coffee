angular.module("ofn.admin").factory "ProductImportService", ($rootScope, $timeout) ->
  new class ProductImportService
    suppliers: {}
    resetCount: 0

    updateResetAbsent: (supplierId, nonUpdated, resetAbsent) ->
      if resetAbsent
        @suppliers[supplierId] = nonUpdated
        @resetCount += nonUpdated
      else
        @suppliers[supplierId] = null
        @resetCount -= nonUpdated

      $rootScope.resetCount = @resetCount

