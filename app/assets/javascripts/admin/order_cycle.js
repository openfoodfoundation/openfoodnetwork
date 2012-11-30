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


function AdminEditOrderCycleCtrl($scope, $http, OrderCycle, Enterprise) {
  $scope.enterprises = {};
  Enterprise.index(function(data) {
    for(i in data) {
      $scope.enterprises[data[i]['id']] = data[i];
    }
  });

  // TODO: Research how to do route param parsing from regular url.
  //       Does Angular have a way to do this?
  OrderCycle.get({order_cycle_id: 24}, function(order_cycle) {
    $scope.order_cycle = order_cycle;
    $scope.order_cycle.incoming_exchanges = [];
    $scope.order_cycle.outgoing_exchanges = [];
    for(i in order_cycle.exchanges) {
      var exchange = order_cycle.exchanges[i];
      if(exchange.sender_id == order_cycle.coordinator_id) {
	$scope.order_cycle.outgoing_exchanges.push({enterprise_id: exchange.receiver_id});

      } else if(exchange.receiver_id == order_cycle.coordinator_id) {
	$scope.order_cycle.incoming_exchanges.push({enterprise_id: exchange.sender_id});

      } else {
	console.log('Exchange between two enterprises, neither of which is coordinator!');
      }
    }

    // TODO: Check if this is the best way
    delete($scope.order_cycle.exchanges);
  });

  $scope.addSupplier = function($event) {
    $event.preventDefault();
    $scope.order_cycle.incoming_exchanges.push({'enterprise_id': $scope.new_supplier_id});
  };
}


angular.module('order_cycle', ['ngResource']).
  config(function($httpProvider) {
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
  }).
  factory('OrderCycle', function($resource) {
    return $resource('/admin/order_cycles/:order_cycle_id.json', {},
		     {'index': { method: 'GET', isArray: true},
		      'show': { method: 'GET', isArray: false}});
  }).
  factory('Enterprise', function($resource) {
    return $resource('/admin/enterprises/:enterprise_id.json', {},
		     {'index': { method: 'GET', isArray: true}});
  });
