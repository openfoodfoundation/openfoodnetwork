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
			var property_name = attrs.ngTrackProduct;
			ngModel.$parsers.push(function(viewValue){
				if (ngModel.$dirty)	{
					addDirtyProperty(scope.dirtyProducts, scope.product.id, property_name, viewValue);
					scope.displayDirtyProducts();
				}
				return viewValue;
			});
		}
	}
});

productsApp.directive('ngTrackVariant', function(){
	return {
		require: 'ngModel',
		link: function(scope, element, attrs, ngModel) {
			var property_name = attrs.ngTrackVariant;
			ngModel.$parsers.push(function(viewValue){
				var dirtyVariants = {};
				if (scope.dirtyProducts.hasOwnProperty(scope.product.id) && scope.dirtyProducts[scope.product.id].hasOwnProperty("variants")) dirtyVariants = scope.dirtyProducts[scope.product.id].variants;
				if (ngModel.$dirty)	{
					addDirtyProperty(dirtyVariants, scope.variant.id, property_name, viewValue);
					addDirtyProperty(scope.dirtyProducts, scope.product.id, "variants", dirtyVariants);
					scope.displayDirtyProducts();
				}
				return viewValue;
			});
		}
	}
});

productsApp.directive('ngToggleVariants',function(){
	return {
		link: function(scope,element,attrs){
			if (scope.displayProperties[scope.product.id].showVariants) { element.removeClass('icon-chevron-right'); element.addClass('icon-chevron-down'); }
			else { element.removeClass('icon-chevron-down'); element.addClass('icon-chevron-right'); }
			element.on('click', function(){
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

productsApp.directive('ngToggleColumn',function(){
	return {
		link: function(scope,element,attrs){
			if (!scope.column.visible) { element.addClass("unselected"); }
			element.click('click', function(){
				scope.$apply(function(){
					if (scope.column.visible) { scope.column.visible = false; element.addClass("unselected"); }
					else { scope.column.visible = true; element.removeClass("unselected"); }
				});
			});
		}
	};
});

productsApp.directive('ngToggleColumnList', ["$compile", function($compile){
	return {
		link: function(scope,element,attrs){
			var dialogDiv = element.next();
			element.on('click',function(){
				var pos = element.position();
				var height = element.outerHeight();
				dialogDiv.css({
					position: "absolute",
					top: (pos.top + height) + "px",
					left: pos.left + "px",
				}).toggle();
			});
		}
	}
}]);

productsApp.directive('datetimepicker', ["$parse", function ($parse) {
  	return {
		require: 'ngModel',
		link: function (scope, element, attrs, ngModel) {
			element.datetimepicker({
				dateFormat: 'yy-mm-dd',
				timeFormat: 'HH:mm:ss',
				stepMinute: 15,
				onSelect:function (dateText, inst) {
					scope.$apply(function(scope){
						ngModel.$setViewValue(dateText); // Fires ngModel.$parsers
					});
				}
			});
		}
	}
}]);
productsApp.controller('AdminBulkProductsCtrl', ["$scope", "$timeout", "$http", "dataFetcher", function($scope, $timeout, $http, dataFetcher) {
	$scope.updateStatusMessage = {
		text: "",
		style: {}
	}

	$scope.columns = {
		name: { name: 'Name', visible: true },
		supplier: { name: 'Supplier', visible: true },
		price: { name: 'Price', visible: true },
		on_hand: { name: 'On Hand', visible: true },
		available_on: { name: 'Available On', visible: true }
	}

	$scope.initialise = function(spree_api_key){
		var authorise_api_reponse = "";
		dataFetcher('/api/users/authorise_api?token='+spree_api_key).then(function(data){
			authorise_api_reponse = data;
			$scope.spree_api_key_ok = data.hasOwnProperty("success") && data["success"] == "Use of API Authorised";
			if ($scope.spree_api_key_ok){
				$http.defaults.headers.common['X-Spree-Token'] = spree_api_key;
				dataFetcher('/api/enterprises/managed?template=bulk_index&q[is_primary_producer_eq]=true').then(function(data){
					$scope.suppliers = data;
					// Need to have suppliers before we get products so we can match suppliers to product.supplier
					dataFetcher('/api/products/managed?template=bulk_index').then(function(data){
						$scope.resetProducts(data);
					});
				});
			}
			else if (authorise_api_reponse.hasOwnProperty("error")){ $scope.api_error_msg = authorise_api_reponse("error"); }
			else{ api_error_msg = "You don't have an API key yet. An attempt was made to generate one, but you are currently not authorised, please contact your site administrator for access." }
		});
	};

	$scope.resetProducts = function(data){
		$scope.products = data;
		$scope.dirtyProducts = {};
		$scope.displayProperties = $scope.displayProperties || {};
		angular.forEach($scope.products,function(product){
			$scope.displayProperties[product.id] = $scope.displayProperties[product.id] || { showVariants: false };
			$scope.matchSupplier(product);
		});
	}

	$scope.matchSupplier = function(product){
		for (i in $scope.suppliers){
			var supplier = $scope.suppliers[i];
			if (angular.equals(supplier,product.supplier)){
				product.supplier = supplier;
				break;
			}
		}
	}

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
				url: '/api/products/'+product.id
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
				url: '/api/products/'+product.id+"/variants/"+variant.id
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
			dataFetcher("/api/products/"+id+"?template=bulk_show").then(function(data){
				var newProduct = data;
				$scope.matchSupplier(newProduct);
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
				$scope.resetProducts(data);
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
}]);

productsApp.factory('dataFetcher', ["$http", "$q", function($http,$q){
	return function(dataLocation){
		var deferred = $q.defer();
		$http.get(dataLocation).success(function(data) {
			deferred.resolve(data);
		}).error(function(){
			deferred.reject();
		});
		return deferred.promise;
	};
}]);

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
				if (product.hasOwnProperty("supplier")) { filteredProduct.supplier_id = product.supplier.id; hasUpdatableProperty = true; }
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