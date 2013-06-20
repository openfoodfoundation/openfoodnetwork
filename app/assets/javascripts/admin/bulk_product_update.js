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

productsApp.directive('ngToggleVariants',function(){
	return {
		link: function(scope,element,attrs){
			element.bind('click', function(){
				scope.$apply(function(){
					if (scope.displayProperties[scope.product.id].showVariants){
						scope.displayProperties[scope.product.id].showVariants = false;
						element.removeClass('icon-chevron-down');
						element.addClass('icon-chevron-right');
					}
					else {
						scope.displayProperties[scope.product.id].showVariants = true;
						element.removeClass('icon-chevron-right');
						element.addClass('icon-chevron-down');
					}
				});
			});
		}
	};
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
			$scope.products = data;
			$scope.displayProperties = {};
			angular.forEach($scope.products,function(product){
				$scope.displayProperties[product.id] = { showVariants: false }
			});
		});
	};

	$scope.updateOnHand = function(product){
		product.on_hand = onHand(product);
	}

	$scope.editWarn = function(product,variant){
		if ( ( $scope.dirtyProductCount() > 0 && confirm("Unsaved changes will be lost. Continue anyway?") ) || ( $scope.dirtyProductCount() == 0 ) ){
			window.location = "/admin/products/"+product.permalink_live+(variant ? "/variants/"+variant.id : "")+"/edit";
		}
	}

	$scope.deleteProduct = function(product){
		if (confirm("Are you sure?")){
			$http({
				method: 'DELETE',
				url: '/admin/products/'+product.permalink_live+".js"
			})
			.success(function(data){
				$scope.products.splice($scope.products.indexOf(product),1);
				if ($scope.dirtyProducts.hasOwnProperty(product.id)) delete $scope.dirtyProducts[product.id];
				$scope.displayDirtyProducts();
			})
		}
	}

	$scope.deleteVariant = function(product,variant){
		if (confirm("Are you sure?")){
			$http({
				method: 'DELETE',
				url: '/admin/products/'+product.permalink_live+"/variants/"+variant.id+".js"
			})
			.success(function(data){
				product.variants.splice(product.variants.indexOf(variant),1);
				if ($scope.dirtyProducts.hasOwnProperty(product.id) && $scope.dirtyProducts[product.id].hasOwnProperty("variants") && $scope.dirtyProducts[product.id].variants.hasOwnProperty(variant.id)) delete $scope.dirtyProducts[product.id].variants[variant.id];
				$scope.displayDirtyProducts();
			})
		}
	}

	$scope.cloneProduct = function(product){
		dataFetcher("/admin/products/"+product.permalink_live+"/clone.json").then(function(data){
			// Ideally we would use Spree's built in respond_override helper here to redirect the user after a successful clone with .json in the accept headers
			// However, at the time of writing there appears to be an issue which causes the respond_with block in the destroy action of Spree::Admin::Product to break
			// when a respond_overrride for the clone action is used.
			var id = data.product.id;
			dataFetcher("/admin/products/bulk_index.json?q[id_eq]="+id).then(function(data){
				var newProduct = data[0];
				$scope.products.push(newProduct);
			});
		});
	}

	$scope.hasVariants = function(product){
		return Object.keys(product.variants).length > 0;
	}

	$scope.updateProducts = function(productsToSubmit){
		$scope.displayUpdating();
		$http({
			method: 'POST',
			url: '/admin/products/bulk_update',
			data: productsToSubmit
		})
		.success(function(data){
			if (angular.toJson($scope.products) == angular.toJson(data)){
				$scope.products = data;
				$scope.dirtyProducts = {};
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
		if (model.timeout) $timeout.cancel(model.timeout);
		if (timeout){
			model.timeout = $timeout(function() { $scope.setMessage(model,"",{},false); }, timeout, true);
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
		if ($scope.dirtyProductCount() > 0) $scope.setMessage($scope.updateStatusMessage,"Changes to "+$scope.dirtyProductCount()+" products remain unsaved.",{ color: "gray" },false);
		else $scope.setMessage($scope.updateStatusMessage,"",{},false);
	}

	$scope.dirtyProductCount = function(){
		return Object.keys($scope.dirtyProducts).length;
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
			if (product.hasOwnProperty("id")){
				var filteredProduct = {};
				var filteredVariants = [];

				if (product.hasOwnProperty("variants")){
					angular.forEach(product.variants, function(variant){
						if (variant.deleted_at == null && variant.hasOwnProperty("id")){
							var hasUpdateableProperty = false;
							var filteredVariant = {};
							filteredVariant.id = variant.id;
							if (variant.hasOwnProperty("on_hand")) { filteredVariant.on_hand = variant.on_hand; hasUpdatableProperty = true; }
							if (variant.hasOwnProperty("price")) { filteredVariant.price = variant.price; hasUpdatableProperty = true; }
							if (hasUpdatableProperty) filteredVariants.push(filteredVariant);
						}
					});
				}

				var hasUpdatableProperty = false;
				filteredProduct.id = product.id;
				if (product.hasOwnProperty("name")) { filteredProduct.name = product.name; hasUpdatableProperty = true; }
				if (product.hasOwnProperty("supplier_id")) { filteredProduct.supplier_id = product.supplier_id; hasUpdatableProperty = true; }
				if (product.hasOwnProperty("price")) { filteredProduct.price = product.price; hasUpdatableProperty = true; }
				if (product.hasOwnProperty("on_hand") && filteredVariants.length == 0) { filteredProduct.on_hand = product.on_hand; hasUpdatableProperty = true; } //only update if no variants present
				if (product.hasOwnProperty("available_on")) { filteredProduct.available_on = product.available_on; hasUpdatableProperty = true; }
				if (filteredVariants.length > 0) { filteredProduct.variants_attributes = filteredVariants; hasUpdatableProperty = true; } // Note that the name of the property changes to enable mass assignment of variants attributes with rails

				if (hasUpdatableProperty) filteredProducts.push(filteredProduct);
			}
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