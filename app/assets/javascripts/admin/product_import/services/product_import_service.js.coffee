angular.module("ofn.admin").factory "ProductImportService", ($rootScope) ->
  new class ProductImportService
    suppliers: {}
    resetTotal: 0

    updateResetAbsent: (supplierId, resetCount, resetAbsent) ->
      if resetAbsent
        @suppliers[supplierId] = resetCount
        @resetTotal += resetCount
      else
        @suppliers[supplierId] = null
        @resetTotal -= resetCount

      $rootScope.resetTotal = @resetTotal

