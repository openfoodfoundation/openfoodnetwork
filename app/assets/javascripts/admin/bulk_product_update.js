function AdminProductsBulkCtrl($scope, $http) {
	$scope.refreshData = function(){
		$http({ method: 'GET', url:'/admin/products/bulk_index.json' }).success(function(data) {
			$scope.products = data;
		});
	}
	$scope.refreshData();
}

var productsApp = angular.module('bulk_product_update', [])