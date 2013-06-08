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
		.success(function(data,status,headers,config){
			delete $scope.products[product.id]
			delete $scope.dirtyProducts[product.id]
		})
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
	if(product.hasOwnProperty('variants') && product.variants instanceof Array){
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
		var productKeys = Object.keys(productsToFilter);
		for (i in productKeys) {
			if (productsToFilter[productKeys[i]].hasOwnProperty("id")){
				var filteredProduct = {};
				var filteredVariants = [];

				if (productsToFilter[productKeys[i]].hasOwnProperty("variants")){
					var variantKeys = Object.keys(productsToFilter[productKeys[i]].variants);
					for (j in variantKeys){
						if (productsToFilter[productKeys[i]].variants[variantKeys[j]].deleted_at == null && productsToFilter[productKeys[i]].variants[variantKeys[j]].hasOwnProperty("id")){
							filteredVariants[j] = {};
							filteredVariants[j].id = productsToFilter[productKeys[i]].variants[variantKeys[j]].id;
							if (productsToFilter[productKeys[i]].variants[variantKeys[j]].hasOwnProperty("on_hand")) filteredVariants[j].on_hand = productsToFilter[productKeys[i]].variants[variantKeys[j]].on_hand;
							if (productsToFilter[productKeys[i]].variants[variantKeys[j]].hasOwnProperty("price")) filteredVariants[j].price = productsToFilter[productKeys[i]].variants[variantKeys[j]].price;
						}
					}
				}

				var hasUpdatableProperty = false;
				filteredProduct.id = productsToFilter[productKeys[i]].id;
				if (productsToFilter[productKeys[i]].hasOwnProperty("name")) { filteredProduct.name = productsToFilter[productKeys[i]].name; hasUpdatableProperty = true; }
				if (productsToFilter[productKeys[i]].hasOwnProperty("supplier_id")) { filteredProduct.supplier_id = productsToFilter[productKeys[i]].supplier_id; hasUpdatableProperty = true; }
				//if (productsToFilter[productKeys[i]].hasOwnProperty("master")) filteredProduct.master_attributes = productsToFilter[productKeys[i]].master
				if (productsToFilter[productKeys[i]].hasOwnProperty("price")) { filteredProduct.price = productsToFilter[productKeys[i]].price; hasUpdatableProperty = true; }
				if (productsToFilter[productKeys[i]].hasOwnProperty("on_hand") && filteredVariants.length == 0) { filteredProduct.on_hand = productsToFilter[productKeys[i]].on_hand; hasUpdatableProperty = true; } //only update if no variants present
				if (productsToFilter[productKeys[i]].hasOwnProperty("available_on")) { filteredProduct.available_on = productsToFilter[productKeys[i]].available_on; hasUpdatableProperty = true; }
				if (filteredVariants.length > 0) { filteredProduct.variants_attributes = filteredVariants; hasUpdatableProperty = true; } // Note that the name of the property changes to enable mass assignment of variants attributes with rails

				if (hasUpdatableProperty) filteredProducts.push(filteredProduct);
			}
		}
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
	if (dirtyObjects.hasOwnProperty(objectID) && Object.keys(dirtyObjects[objectID]).length <= 1)	delete dirtyObjects[objectID];
}

function toObjectWithIDKeys(array){
	object = {};
	if (array instanceof Array){
		for (i in array){
			if (array[i].hasOwnProperty("id")){
				object[array[i].id] = array[i];
			}
		}
	}
	return object;
}