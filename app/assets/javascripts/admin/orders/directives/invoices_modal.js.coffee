angular.module("admin.orders").directive "invoicesModal", ($modal) ->
  restrict: 'C'
  link: (scope, elem, attrs, ctrl) ->
    elem.on "click", (ev) =>
      scope.uploadModal = $modal.open(templateUrl: 'admin/modals/bulk_invoice.html', controller: ctrl, scope: scope, windowClass: 'simple-modal')
