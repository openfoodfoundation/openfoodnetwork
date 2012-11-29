function AdminOrderCycleCtrl($scope, $http) {
  $http.get('/admin/order_cycles/new.json').success(function(data) {
    $scope.order_cycle = data;
    $scope.order_cycle.incoming_exchanges = [];
    $scope.order_cycle.outgoing_exchanges = [];
  });

  $http.get('/admin/enterprises.json').success(function(data) {
    $scope.enterprises = {};

    for(i in data) {
      $scope.enterprises[data[i]['id']] = data[i];
    }
  });

  $scope.addSupplier = function($event) {
    $event.preventDefault();
    $scope.order_cycle.incoming_exchanges.push({'enterprise_id': $scope.new_supplier_id});
  };

  $scope.submit = function() {
    $http.post('/admin/order_cycles', {order_cycle: $scope.order_cycle}).success(function(data) {
      if(data['success']) {
	window.location = '/admin/order_cycles';
      } else {
	console.log('fail');
      }
    });
  };
}

angular.module('order_cycle', []).
  config(function($httpProvider) {
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
  });
