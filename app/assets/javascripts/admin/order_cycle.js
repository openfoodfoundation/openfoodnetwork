function AdminOrderCycleCtrl($scope, $http) {
  $http.get('/admin/order_cycles/new.json').success(function(data) {
    $scope.order_cycle = data;
  });

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
