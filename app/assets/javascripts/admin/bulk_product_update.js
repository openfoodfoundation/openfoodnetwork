var productsApp = angular.module('bulk_product_update', [])

productsApp.config(["$httpProvider", function(provider) {
  provider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
}]);

productsApp.directive('ngDecimal', function () {
	return {
		require: 'ngModel',
		link: function(scope, element, attrs, ngModel) {
			var numRegExp = /^\d+(\.\d+)?$/;
			
			element.bind('blur', function() {
				scope.$apply(ngModel.$setViewValue(ngModel.$modelValue));
				ngModel.$render();
			});
			
			ngModel.$setValidity('notADecimalError', function(){
				if (angular.isString(ngModel.$modelValue) && numRegExp.test(ngModel.$modelValue)){
					return true;
				}
				else{
					return false;
				}
			});
			
			ngModel.$parsers.push(function(viewValue){
				if (angular.isString(viewValue) && numRegExp.test(viewValue)){
					if (viewValue.indexOf(".") == -1){
						return viewValue+".0";
					}
				}
				return viewValue;
			});
		}
	}
});

productsApp.directive('ngTrackProduct', function(){
	return {
		require: 'ngModel',
		link: function(scope, element, attrs, ngModel) {
			var property = attrs.ngTrackProduct;
			var clean_value = angular.copy(scope.product[property]);
			element.bind('blur', function() {
				if (scope.product[property] == clean_value) removeCleanProperty(scope.dirtyProducts, scope.product.id, property);
				else addDirtyProperty(scope.dirtyProducts, scope.product.id, property, scope.product[property]);
				scope.$apply(scope.displayDirtyProducts());
			});
		}
	}
});

productsApp.directive('ngTrackVariant', function(){
	return {
		require: 'ngModel',
		link: function(scope, element, attrs, ngModel) {
			var property = attrs.ngTrackVariant;
			var clean_value = angular.copy(scope.variant[property]);
			element.bind('blur', function() {
				var dirtyVariants = {};
				if (scope.dirtyProducts.hasOwnProperty(scope.product.id) && scope.dirtyProducts[scope.product.id].hasOwnProperty("variants")) dirtyVariants = scope.dirtyProducts[scope.product.id].variants;
				if (scope.variant[property] == clean_value){
					removeCleanProperty(dirtyVariants, scope.variant.id, property);
					if (dirtyVariants == {}) removeCleanProperty(scope.dirtyProducts, scope.product.id, "variants");
				}
				else {
					addDirtyProperty(dirtyVariants, scope.variant.id, property, scope.variant[property]);
					addDirtyProperty(scope.dirtyProducts, scope.product.id, "variants", dirtyVariants);
				}
				scope.$apply(scope.displayDirtyProducts());
			});
		}
	}
});

productsApp.controller('AdminBulkProductsCtrl', function($scope, $timeout, $http, dataFetcher) {
	$scope.dirtyProducts = {};

	$scope.updateStatusMessage = {
		text: "",
		style: {}
	}

	$scope.refreshSuppliers = function(){
		dataFetcher('/enterprises/suppliers.json').then(function(data){
			$scope.suppliers = data;
		});
	};

	$scope.refreshProducts = function(){
		dataFetcher('/admin/products/bulk_index.json').then(function(data){
			$scope.products = toObjectWithIDKeys(data);
		});
	};

	$scope.updateOnHand = function(product){
		product.on_hand = onHand(product);
	}

	$scope.deleteProduct = function(product){
		$http({
			method: 'DELETE',
			url: '/admin/products/'+product.permalink_live+".js"
		})
		.success(function(data){
			delete $scope.products[product.id]
			if ($scope.dirtyProducts.hasOwnProperty(product.id)) delete $scope.dirtyProducts[product.id]
		})
	}

	$scope.deleteVariant = function(product,variant){
		$http({
			method: 'DELETE',
			url: '/admin/products/'+product.permalink_live+"/variants/"+variant.id+".js"
		})
		.success(function(data){
			delete $scope.products[product.id].variants[variant.id]
			if ($scope.dirtyProducts.hasOwnProperty(product.id) && $scope.dirtyProducts[product.id].hasOwnProperty("variants") && $scope.dirtyProducts[product.id].variants.hasOwnProperty(variant.id)) delete $scope.dirtyProducts[product.id].variants[variant.id]
		})
	}

	$scope.hasVariants = function(product){
		return !angular.equals(product.variants,{});
	}

	$scope.updateProducts = function(productsToSubmit){
		$scope.displayUpdating();
		$http({
			method: 'POST',
			url: '/admin/products/bulk_update',
			data: productsToSubmit
		})
		.success(function(data){
			data = toObjectWithIDKeys(data);
			if (angular.toJson($scope.products) == angular.toJson(data)){
				$scope.products = data;
				$scope.displaySuccess();
			}
			else{
				$scope.displayFailure("Product lists do not match.");
			}
		})
		.error(function(data,status){
			$scope.displayFailure("Server returned with error status: "+status);
		});
	}

	$scope.prepareProductsForSubmit = function(){
		var productsToSubmit = filterSubmitProducts($scope.dirtyProducts);
		$scope.updateProducts(productsToSubmit);
	}

	$scope.setMessage = function(model,text,style,timeout){
		model.text = text;
		model.style = style;
		if (timeout){
			$timeout(function() { $scope.setMessage(model,"",{},false); }, timeout, true);
		}
	}

	$scope.displayUpdating = function(){
		$scope.setMessage($scope.updateStatusMessage,"Updating...",{ color: "orange" },false);
	}

	$scope.displaySuccess = function(){
		$scope.setMessage($scope.updateStatusMessage,"Update complete",{ color: "green" },3000);
	}

	$scope.displayFailure = function(failMessage){
		$scope.setMessage($scope.updateStatusMessage,"Updating failed. "+failMessage,{ color: "red" },10000);
	}

	$scope.displayDirtyProducts = function(){
		var changedProductCount = Object.keys($scope.dirtyProducts).length;
		if (changedProductCount > 0) $scope.setMessage($scope.updateStatusMessage,"Changes to "+Object.keys($scope.dirtyProducts).length+" products remain unsaved.",{ color: "gray" },false);
		else $scope.setMessage($scope.updateStatusMessage,"",{},false);
	}
});

productsApp.factory('dataFetcher', function($http,$q){
	return function(dataLocation){
		var deferred = $q.defer();
		$http.get(dataLocation).success(function(data) {
			deferred.resolve(data);
		}).error(function(){
			deferred.reject();
		});
		return deferred.promise;
	};
});

function onHand(product){
	var onHand = 0;
	if(product.hasOwnProperty('variants') && product.variants instanceof Object){
		angular.forEach(product.variants, function(variant) {
			onHand = parseInt( onHand ) + parseInt( variant.on_hand > 0 ? variant.on_hand : 0 );
		});
	}
	else{
		onHand = 'error';
	}
	return onHand;
}

function filterSubmitProducts(productsToFilter){
	var filteredProducts= [];

	if (productsToFilter instanceof Object){
		angular.forEach(productsToFilter, function(product){
		//var productKeys = Object.keys(productsToFilter);
		//for (i in productKeys) {
			if (product.hasOwnProperty("id")){
				var filteredProduct = {};
				var filteredVariants = [];

				if (product.hasOwnProperty("variants")){
					angular.forEach(product.variants, function(variant){
					//var variantKeys = Object.keys(product.variants);
					//for (j in variantKeys){
						if (variant.deleted_at == null && variant.hasOwnProperty("id")){
							var hasUpdateableProperty = false;
							var filteredVariant = {};
							filteredVariant.id = variant.id;
							if (variant.hasOwnProperty("on_hand")) { filteredVariant.on_hand = variant.on_hand; hasUpdatableProperty = true; }
							if (variant.hasOwnProperty("price")) { filteredVariant.price = variant.price; hasUpdatableProperty = true; }
							if (hasUpdatableProperty) filteredVariants.push(filteredVariant);
						}
					//}
					});
				}

				var hasUpdatableProperty = false;
				filteredProduct.id = product.id;
				if (product.hasOwnProperty("name")) { filteredProduct.name = product.name; hasUpdatableProperty = true; }
				if (product.hasOwnProperty("supplier_id")) { filteredProduct.supplier_id = product.supplier_id; hasUpdatableProperty = true; }
				//if (product.hasOwnProperty("master")) filteredProduct.master_attributes = product.master
				if (product.hasOwnProperty("price")) { filteredProduct.price = product.price; hasUpdatableProperty = true; }
				if (product.hasOwnProperty("on_hand") && filteredVariants.length == 0) { filteredProduct.on_hand = product.on_hand; hasUpdatableProperty = true; } //only update if no variants present
				if (product.hasOwnProperty("available_on")) { filteredProduct.available_on = product.available_on; hasUpdatableProperty = true; }
				if (filteredVariants.length > 0) { filteredProduct.variants_attributes = filteredVariants; hasUpdatableProperty = true; } // Note that the name of the property changes to enable mass assignment of variants attributes with rails

				if (hasUpdatableProperty) filteredProducts.push(filteredProduct);
			}
		//}
		});
	}
	return filteredProducts;
}

function addDirtyProperty(dirtyObjects, objectID, propertyName, propertyValue){
	if (dirtyObjects.hasOwnProperty(objectID)){
		dirtyObjects[objectID][propertyName] = propertyValue;
	}
	else {
		dirtyObjects[objectID] = {};
		dirtyObjects[objectID]["id"] = objectID;
		dirtyObjects[objectID][propertyName] = propertyValue;
	}
}

function removeCleanProperty(dirtyObjects, objectID, propertyName){
	if (dirtyObjects.hasOwnProperty(objectID) && dirtyObjects[objectID].hasOwnProperty(propertyName)) delete dirtyObjects[objectID][propertyName];
	if (dirtyObjects.hasOwnProperty(objectID) && Object.keys(dirtyObjects[objectID]).length <= 1) delete dirtyObjects[objectID];
}

function toObjectWithIDKeys(array){
	var object = {};
	//if (array instanceof Array){
		for (i in array){
			if (array[i] instanceof Object && array[i].hasOwnProperty("id")){
				object[array[i].id] = angular.copy(array[i]);
				if (array[i].hasOwnProperty("variants") && array[i].variants instanceof Array){
					object[array[i].id].variants = toObjectWithIDKeys(array[i].variants);
				}
			}
		}
	//}
	return object;
}