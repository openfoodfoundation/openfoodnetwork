describe("Auxillary functions", function(){

	describe("sorting objects by id", function(){
		var a, b;

		beforeEach(function(){
			a = [ { id: 1, value: 10 }, { id: 2, value: 20 }, { id: 3, value: 30 }, { notanid: 4, value: 40 } ];
			b = [ { id: 3, value: 30 }, { id: 2, value: 20 }, { id: 1, value: 10 } ];
		});

		it("returns only objects with an id", function(){
			expect(sortByID(a)).toEqual( [ { id: 1, value: 10 }, { id: 2, value: 20 }, { id: 3, value: 30 } ] );
		});

		it("returns objects in a list sorted by id", function(){
			expect(sortByID(b)).toEqual( [ { id: 1, value: 10 }, { id: 2, value: 20 }, { id: 3, value: 30 } ] );
		});
	});

	describe("finding matching objects", function() {
		var a, b, c, d, e;

		beforeEach(function(){
			a = [ { id: 1, value: 10 }, { id: 2, value: 20 } ];
			b = [ { id: 1, value: 11 }, { id: 2, value: 22 } ];
			c = [ { id: 1, value: 12 }, { id: 2, value: 23 }, { id: 3, value: 34 } ];
			d = [ { id: 1, value: 13 }, { id: 2, value: 24 }, { id: 4, value: 46 } ];
			e = [ { id: 1, value: 14 }, { id: 2, value: 25 }, { id: 3, value: 34 }, { notanid: 12, value: 47 } ];

			spyOn(window, "sortByID").andCallThrough();
		});

		it("calls sortByID once for each input array", function(){
			matchedObjects = getMatchedObjects(a, b);
			expect(sortByID.calls.length).toEqual(2);
			expect(sortByID).toHaveBeenCalledWith(a);
			expect(sortByID).toHaveBeenCalledWith(b);
		});

		it("returns only objects with an id in the test list", function() { 
			expect( getMatchedObjects(a, b) ).toEqual( [ { id: 1, value: 11 }, { id: 2, value: 22 } ]);
		});

		it("returns only objects with an id in testList, ignores objects with ids which only appear in cleanlist", function(){
			expect( getMatchedObjects(b, c) ).toEqual( [ { id: 1, value: 12 }, { id: 2, value: 23 } ]);
		});

		it("creates a duplicate entry the in returned list for objects in listOne that are absent from cleanList (as determined by id)", function() { 
			expect( getMatchedObjects(c, d) ).toEqual( [ { id: 1, value: 13 }, { id: 2, value: 24 }, { id: 3, value: 34 } ]);
		});

		it("always returns a list of objects equal in length to the length of the testList, minus items without an id", function(){
			expect( getMatchedObjects(d, e) ).toEqual( [ { id: 1, value: 14 }, { id: 2, value: 25 }, { id: 4, value: 46 } ]);
			expect( getMatchedObjects(e, d) ).toEqual( [ { id: 1, value: 13 }, { id: 2, value: 24 }, { id: 3, value: 34 } ]);
		});
	});

	describe("Getting dirty properties of objects", function() {
		var a, b, c, d;

		beforeEach(function(){
			a = { id: 1, "1": 1, "2": 5, "3": 3 };
			b = { id: 1, "1": 1, "2": 2, "3": 3 };
			c = { id: 1, "1": 1, "2": 2, "3": 3, "4": 4 };
			d = { id: 2, "1": 2, "2": 6, "3": 8 };
		});

		it("returns only differing properties when object do not match", function() {
			expect( getDirtyProperties(a, b) ).toEqual( { "2": 5 } );
			expect( getDirtyProperties(b, b) ).toEqual( {} );
		});

		it("ignores properties which are not possessed by both objects", function() {
			expect( getDirtyProperties(b, c) ).toEqual( {} );
			expect( getDirtyProperties(c, b) ).toEqual( {} );
		});
		
		it("sends and properties which are objects back to getDirtyObjects",function(){
			spyOn(window, "getDirtyObjects");
			getDirtyProperties( { id: 1, num: 3, object: { id: 1, value: "something" } }, { id: 1, num: 2, object: { id: 1, value: "somethingelse" } } );
			expect(getDirtyObjects.calls.length).toEqual(1);
			expect(getDirtyObjects).toHaveBeenCalledWith( [ { id: 1, value: "something" } ], [ { id: 1, value: "somethingelse" } ] );
		})
	});

	describe("Getting dirty objects", function() {
		var a, b, c, d;
		beforeEach(function(){
			a = [ { id: 1, value: 10 }, { id: 2, value: 20 } ];
			b = [ { id: 1, value: 10 }, { id: 2, value: 15 } ];
			c = [ { id: 1, value: 10 }, { id: 2, value: 12 }, { id: 3, value1: 10, value2: 15 } ];
			d = [ { id: 1, value: 10 }, { id: 2, value: 20 }, { id: 3, value1: 10, value2: 20 } ];
		});

		it("calls getMatchedObjects() once for each call to getDirtyItems", function(){
			spyOn(window, "getMatchedObjects").andReturn(b);
			spyOn(window, "getDirtyProperties");
			var dirtyObjects = getDirtyObjects(a, b);

			expect(getMatchedObjects.calls.length).toEqual(1);
			expect(getMatchedObjects).toHaveBeenCalledWith(a,b);
		});

		it("calls sortByID once for the test Array", function(){
			spyOn(window, "getMatchedObjects").andReturn(b);
			spyOn(window, "sortByID");
			spyOn(window, "getDirtyProperties");
			var dirtyObjects = getDirtyObjects(a, b);

			expect(sortByID.calls.length).toEqual(1);
			expect(sortByID).toHaveBeenCalledWith(a);
		});

		it("returns only valid (non-empty) objects returned by getDirtyProperties", function(){
			expect( getDirtyObjects(a, b) ).not.toContain( {} );
		});

		it("adds an id property to any non-empty object that is returned to it", function(){
			expect( getDirtyObjects(a, b) ).toEqual( [ { id: 2, value: 20 } ] );
		});

		it("calls getDirtyProperties() once for each pair of objects", function(){
			spyOn(window, "getMatchedObjects").andReturn(b);
			spyOn(window, "getDirtyProperties").andCallThrough();
			var dirtyObjects = getDirtyObjects(a, b);

			expect(getDirtyProperties.calls.length).toEqual(2);
			expect(getDirtyProperties).toHaveBeenCalledWith(a[0],b[0]);
			expect(getDirtyProperties).toHaveBeenCalledWith(a[1],b[1]);
		});

		it("returns an array of objects identified by their ids, and any additional differing properties", function(){
			expect( getDirtyObjects(c, d) ).toEqual( [ { id: 2, value: 12 }, { id: 3, value2: 15 } ] );
		});
	});
});


describe("AdminBulkProductsCtrl", function(){
	ctrl = null;
	scope = null;
	timeout = null;
	httpBackend = null;
	supplierController = null;

	beforeEach(inject(function($controller,$rootScope,$timeout,$httpBackend) {
		scope = $rootScope.$new();
		timeout = $timeout;
		ctrl = $controller;
		httpBackend = $httpBackend;
	}));
	
	describe("loading data upon initialisation", function(){
		it("gets a list of suppliers, a list of products and stores a clean list of products", function(){
			httpBackend.expectGET('/enterprises/suppliers.json').respond("list of suppliers");
			httpBackend.expectGET('/admin/products/bulk_index.json').respond("list of products");
			ctrl('AdminBulkProductsCtrl', { $scope: scope } );
			httpBackend.flush();
			expect(scope.suppliers).toEqual("list of suppliers");
			expect(scope.products).toEqual("list of products");
			expect(scope.cleanProducts).toEqual("list of products");
		});
		
		it("does not affect clean products list when products list is altered", function(){
			httpBackend.expectGET('/enterprises/suppliers.json').respond("list of suppliers");
			httpBackend.expectGET('/admin/products/bulk_index.json').respond( [1,2,3,4,5] );
			ctrl('AdminBulkProductsCtrl', { $scope: scope } );
			httpBackend.flush();
			expect(scope.products).toEqual( [1,2,3,4,5] );
			expect(scope.cleanProducts).toEqual( [1,2,3,4,5] );
			scope.products.push(6);
			expect(scope.products).toEqual( [1,2,3,4,5,6] );
			expect(scope.cleanProducts).toEqual( [1,2,3,4,5] );
		});
	});
	
	describe("filtering products", function(){
		it("only accepts and returns an array", function(){
			expect( filterSubmitProducts( [] ) ).toEqual([]);
			expect( filterSubmitProducts( {} ) ).toEqual([]);
			expect( filterSubmitProducts( { thingone: { id: 1, name: "lala" } } ) ).toEqual([]);
			expect( filterSubmitProducts( 1 ) ).toEqual([]);
			expect( filterSubmitProducts( "2" ) ).toEqual([]);
			expect( filterSubmitProducts( null ) ).toEqual([]);
		});
		
		it("only returns products which have an id property", function(){
			expect( filterSubmitProducts( [ { id: 1, name: "p1" }, { notanid: 2, name: "p2"} ] ) ).toEqual( [ { id: 1, name: "p1" } ]);
		});
		
		it("returns variants as variants_attributes", function(){
			var testProduct  = {
				id: 1,
				variants: [ {
					id: 1,
					on_hand: 5,
					price: 12.0
				} ]
			};
			expect( filterSubmitProducts( [ testProduct ] ) ).toEqual( [ {
				id: 1,
				variants_attributes: [ {
					id: 1,
					on_hand: 5,
					price: 12.0
				} ]
			} ] );
		});
		
		it("returns master as master_attributes", function(){
			var testProduct  = {
				id: 1,
				master: [ {
					id: 1,
					on_hand: 5,
					price: 12.0
				} ]
			};
			expect( filterSubmitProducts( [ testProduct ] ) ).toEqual( [ {
				id: 1,
				master_attributes: [ {
					id: 1,
					on_hand: 5,
					price: 12.0
				} ]
			} ] );
		});
		
		it("ignores variants without an id, and those for which deleted_at is not null", function(){
			var testProduct  = {
				id: 1,
				variants: [ {
					id: 1,
					on_hand: 3,
					price: 5.0
				},
				{
					on_hand: 1,
					price: 15.0
				},
				{
					id: 2,
					on_hand: 2,
					deleted_at: new Date(),
					price: 20.0
				} ]
			};
			expect( filterSubmitProducts( [ testProduct ] ) ).toEqual( [ {
				id: 1,
				variants_attributes: [ {
					id: 1,
					on_hand: 3,
					price: 5.0
				} ]
			} ] );
		});
		
		// TODO Not an exhaustive test, is there a better way to do this?
		it("only returns properties the properties of products which ought to be updated", function(){
			var testProduct  = {
				id: 1,
				name: "TestProduct",
				description: "",
				available_on: new Date(),
				deleted_at: null,
				permalink: null,
				meta_description: null,
				meta_keywords: null,
				tax_category_id: null,
				shipping_category_id: null,
				created_at: null,
				updated_at: null,
				count_on_hand: 0,
				supplier_id: 5,
				group_buy: null,
				group_buy_unit_size: null,
				on_demand: false,
				variants: [ {
					id: 1,
					on_hand: 2,
					price: 10.0
				} ]						
			};

			expect(filterSubmitProducts( [ testProduct ] ) ).toEqual([
				{
					id: 1,
					name: "TestProduct",
					supplier_id: 5,
					available_on: new Date(),
					variants_attributes: [ {
						id: 1,
						on_hand: 2,
						price: 10.0
					} ]						
				} ]
			);
		});
	});
	
	describe("submitting products to be updated", function(){
		describe("preparing products for submit",function(){
			beforeEach(function(){
				httpBackend.expectGET('/enterprises/suppliers.json').respond("list of suppliers");
				httpBackend.expectGET('/admin/products/bulk_index.json').respond( [1,2,3,4,5] );
				ctrl('AdminBulkProductsCtrl', { $scope: scope } );
				httpBackend.flush();
				spyOn(window, "getDirtyObjects").andReturn( [ { id: 1, value: 1 }, { id:2, value: 2 } ] );
				spyOn(window, "filterSubmitProducts").andReturn( [ { id: 1, value: 3 }, { id:2, value: 4 } ] );
				spyOn(scope, "updateProducts");
				scope.prepareProductsForSubmit();
			});
			
			it("fetches dirty products required for submitting", function(){
				expect(getDirtyObjects).toHaveBeenCalledWith([1,2,3,4,5],[1,2,3,4,5]);
			});
			
			it("filters returned dirty products", function(){
				expect(filterSubmitProducts).toHaveBeenCalledWith( [ { id: 1, value: 1 }, { id:2, value: 2 } ] );
			});
			
			it("sends dirty and filtered objects to submitProducts()", function(){
				expect(scope.updateProducts).toHaveBeenCalledWith( [ { id: 1, value: 3 }, { id:2, value: 4 } ] );
			});
		});
		
		describe("updating products",function(){
			beforeEach(function(){
				httpBackend.expectGET('/enterprises/suppliers.json').respond("list of suppliers");
				httpBackend.expectGET('/admin/products/bulk_index.json').respond("list of products");
				ctrl('AdminBulkProductsCtrl', { $scope: scope, $timeout: timeout } );
				httpBackend.flush();
			});
			
			it("submits products to be updated with a http post request to /admin/products/bulk_update", function(){
				httpBackend.expectPOST('/admin/products/bulk_update').respond("list of products");
				scope.updateProducts("list of products");
				httpBackend.flush();
			});
			
			it("runs displaySuccess() when post returns success",function(){
				spyOn(scope, "displaySuccess");
				scope.products = "updated list of products";
				httpBackend.expectPOST('/admin/products/bulk_update').respond(200, "updated list of products");
				scope.updateProducts("updated list of products");
				httpBackend.flush();
				expect(scope.displaySuccess).toHaveBeenCalled();
			});
			
			it("runs displayFailure() when post return data does not match $scope.products",function(){
				spyOn(scope, "displayFailure");
				scope.products = "current list of products";
				httpBackend.expectPOST('/admin/products/bulk_update').respond(200, "returned list of products");
				scope.updateProducts("updated list of products");
				httpBackend.flush();
				expect(scope.displayFailure).toHaveBeenCalled();
			});
			
			it("runs displayFailure() when post returns error",function(){
				spyOn(scope, "displayFailure");
				scope.products = "updated list of products";
				httpBackend.expectPOST('/admin/products/bulk_update').respond(404, "updated list of products");
				scope.updateProducts("updated list of products");
				httpBackend.flush();
				expect(scope.displayFailure).toHaveBeenCalled();
			});			
		});
	});	
});