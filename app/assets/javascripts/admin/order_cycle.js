function AdminCreateOrderCycleCtrl($scope, $http, Enterprise) {
  $scope.order_cycle = {};
  $scope.order_cycle.incoming_exchanges = [];
  $scope.order_cycle.outgoing_exchanges = [];

  $scope.enterprises = {};
  Enterprise.index(function(data) {
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

angular.module('order_cycle', ['ngResource']).
  config(function($httpProvider) {
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
  }).
  factory('Enterprise', function($resource) {
    return $resource('/admin/enterprises/:enterprise_id.json', {},
		     {'index': { method: 'GET', isArray: true}});
  });
