function AdminBulkProductsCtrl($scope, $timeout, $http) {
	$scope.refreshSuppliers = function(){
		$http.get('/enterprises/suppliers.json').success(function(data) {
			$scope.suppliers = data;
		});
	};
	
	$scope.refreshProducts = function(){
		$http({ method: 'GET', url:'/admin/products/bulk_index.json' }).success(function(data) {
			$scope.products = clone(data);
			$scope.cleanProducts = clone(data);
		});
	}
	
	$scope.refreshSuppliers();
	$scope.refreshProducts();
	$scope.updateStatusMessage = {
		text: "",
		style: {}
	}
	
	$scope.updateProducts = function(productsToSubmit){
		$scope.displayUpdating();
		$http({
			method: 'POST',
			url: '/admin/products/bulk_update',
			data: productsToSubmit,
			headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}
		})
		.success(function(data){
			if (angular.toJson($scope.products) == angular.toJson(data)){
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
		var productsToSubmit = getDirtyObjects($scope.products,$scope.cleanProducts);
		productsToSubmit = filterSubmitProducts(productsToSubmit);
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
}

var productsApp = angular.module('bulk_product_update', [])

function sortByID(array){
	var sortedArray = [];
	for (var i in array){
		if (array[i].hasOwnProperty("id")){
			sortedArray.push(array[i]);
		}
	}
	sortedArray.sort(function(a, b){
		return a.id - b.id;
	});
	return sortedArray;
}

// This function returns all objects in cleanList which are able to be matched to an bjects in ListOne using the id properties of each
// In the event that no items in cleanList match the id of an item in testList, the testList item is duplicated and placed into the returned lits
// This means that the returned list has an identical length and identical ids to the testList, with only the values of other properties differing
function getMatchedObjects(testList, cleanList){
	testList = sortByID(testList);
	cleanList = sortByID(cleanList);
	
	var matchedObjects = [];
	var ti = 0, ci = 0;
	
	while (ti < testList.length){
		if (testList[ti].hasOwnProperty("id")){
			if (cleanList[ci].hasOwnProperty("id")){
				while (ci < cleanList.length && cleanList[ci].id<testList[ti].id){
					ci++;
				}
				if (cleanList[ci] && cleanList[ci].hasOwnProperty("id") && cleanList[ci].id==testList[ti].id){
					matchedObjects.push(cleanList[ci])
				}
				else{
					matchedObjects.push(testList[ti])
				}
			}
		}
		ti++;
	}
	return matchedObjects;
}

function getDirtyProperties(testObject, cleanObject){
	var dirtyProperties = {};
	for (var key in testObject){
		if (testObject.hasOwnProperty(key) && cleanObject.hasOwnProperty(key)){
			if (testObject[key] != cleanObject[key]){
				if (testObject[key] instanceof Array){
					dirtyProperties[key] = getDirtyObjects(testObject[key],cleanObject[key]); //only works for objects with id
				}
				else if(testObject[key] instanceof Object){
					dirtyProperties[key] = getDirtyObjects([testObject[key]],[cleanObject[key]]); //only works for objects with id
				}
				else{
					dirtyProperties[key] = testObject[key];
				}
			}
		}
	}
	return dirtyProperties;
}

function getDirtyObjects(testObjects, cleanObjects){
	var dirtyObjects = [];
	var matchedCleanObjects = getMatchedObjects(testObjects,cleanObjects);
	testObjects = sortByID(testObjects);
	
	for (var i in testObjects){
		var dirtyObject = getDirtyProperties(testObjects[i], matchedCleanObjects[i])
		if ( !isEmpty(dirtyObject) ){
			dirtyObject["id"] = testObjects[i].id;
			dirtyObjects.push(dirtyObject);
		}
	}
	return dirtyObjects;
}

function filterSubmitProducts(productsToFilter){
	var filteredProducts= [];

	if (productsToFilter instanceof Array){
		for (i in productsToFilter) {
			if (productsToFilter[i].hasOwnProperty("id")){
				var filteredProduct = {};
				filteredProduct.id = productsToFilter[i].id;
				if (productsToFilter[i].hasOwnProperty("supplier_id")) filteredProduct.supplier_id = productsToFilter[i].supplier_id;
				if (productsToFilter[i].hasOwnProperty("name")) filteredProduct.name = productsToFilter[i].name;
				if (productsToFilter[i].hasOwnProperty("available_on")) filteredProduct.available_on = productsToFilter[i].available_on;
				if (productsToFilter[i].hasOwnProperty("variants")){ 
					var filteredVariants = [];
					for (j in productsToFilter[i].variants){
						if (productsToFilter[i].variants[j].deleted_at == null && productsToFilter[i].variants[j].hasOwnProperty("id")){
							filteredVariants[j] = {};
							filteredVariants[j].id = productsToFilter[i].variants[j].id;
							if (productsToFilter[i].variants[j].hasOwnProperty("on_hand")) filteredVariants[j].on_hand = productsToFilter[i].variants[j].on_hand;
							if (productsToFilter[i].variants[j].hasOwnProperty("price")) filteredVariants[j].price = productsToFilter[i].variants[j].price;
						}
					}
					filteredProduct.variants_attributes = filteredVariants; // Note that the name of the property changes to enable mass assignment of variants attributes with rails
				}
				if (productsToFilter[i].hasOwnProperty("master")) filteredProduct.master_attributes = productsToFilter[i].master
				filteredProducts.push(filteredProduct);
			}
		}
	}
	return filteredProducts;
}

function isEmpty(object){
    for (var i in object){
        if (object.hasOwnProperty(i)){
            return false;
        }
    }
    return true;
}

// A. Levy http://stackoverflow.com/questions/728360/most-elegant-way-to-clone-a-javascript-object
function clone(obj) {
    // Handle the 3 simple types, and null or undefined
    if (null == obj || "object" != typeof obj) return obj;

    // Handle Date
    if (obj instanceof Date) {
        var copy = new Date();
        copy.setTime(obj.getTime());
        return copy;
    }

    // Handle Array
    if (obj instanceof Array) {
        var copy = [];
        for (var i = 0, len = obj.length; i < len; i++) {
            copy[i] = clone(obj[i]);
        }
        return copy;
    }

    // Handle Object
    if (obj instanceof Object) {
        var copy = {};
        for (var attr in obj) {
            if (obj.hasOwnProperty(attr)) copy[attr] = clone(obj[attr]);
        }
        return copy;
    }
}