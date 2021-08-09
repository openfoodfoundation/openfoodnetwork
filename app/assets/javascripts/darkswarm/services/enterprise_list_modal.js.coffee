angular.module('Darkswarm').factory "EnterpriseListModal", ($modal, $rootScope, $http, EnterpriseModal)->
  new class EnterpriseListModal
    open: (enterprises)->
      scope = $rootScope.$new(true)
      scope.enterprises = enterprises
      scope.openModal = EnterpriseModal.open
      if Object.keys(enterprises).length > 1
        $modal.open(templateUrl: "enterprise_list_modal.html", scope: scope)
      else
        EnterpriseModal.open enterprises[Object.keys(enterprises)[0]]
