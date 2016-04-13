describe "InventoryItems service", ->
  InventoryItems = InventoryItemResource = inventoryItems = $httpBackend = null
  inventoryItems = {}

  beforeEach ->
    module 'admin.inventoryItems'
    module ($provide) ->
      $provide.value 'inventoryItems', inventoryItems
      null

    inject ($q, _$httpBackend_, _InventoryItems_, _InventoryItemResource_) ->
      InventoryItems = _InventoryItems_
      InventoryItemResource = _InventoryItemResource_
      $httpBackend = _$httpBackend_


  describe "#setVisiblity", ->
    describe "on an inventory item that already exists", ->
      existing = null

      beforeEach ->
        existing = new InventoryItemResource({ id: 1, enterprise_id: 2, variant_id: 3, visible: true })
        InventoryItems.inventoryItems[2] = {}
        InventoryItems.inventoryItems[2][3] = existing

      describe "success", ->
        beforeEach ->
          $httpBackend.expectPUT('/admin/inventory_items/1.json', { id: 1, enterprise_id: 2, variant_id: 3, visible: false } )
          .respond 200, { id: 1, enterprise_id: 2, variant_id: 3, visible: false }
          InventoryItems.setVisibility(2,3,false)

        it "saves the new visible value AFTER the request responds successfully", ->
          expect(InventoryItems.inventoryItems[2][3].visible).toBe true
          $httpBackend.flush()
          expect(InventoryItems.inventoryItems[2][3].visible).toBe false

      describe "failure", ->
        beforeEach ->
          $httpBackend.expectPUT('/admin/inventory_items/1.json',{ id: 1, enterprise_id: 2, variant_id: 3, visible: null })
          .respond 422, { errors: ["Visible must be true or false"] }
          InventoryItems.setVisibility(2,3,null)

        it "store the errors in the errors object", ->
          expect(InventoryItems.errors).toEqual {}
          $httpBackend.flush()
          expect(InventoryItems.errors[2][3]).toEqual ["Visible must be true or false"]

    describe "on an inventory item that does not exist", ->
      describe "success", ->
        beforeEach ->
          $httpBackend.expectPOST('/admin/inventory_items.json', { enterprise_id: 5, variant_id: 6, visible: false } )
          .respond 200, { id: 1, enterprise_id: 2, variant_id: 3, visible: false }
          InventoryItems.setVisibility(5,6,false)

        it "saves the new visible value AFTER the request responds successfully", ->
          expect(InventoryItems.inventoryItems).toEqual {}
          $httpBackend.flush()
          expect(InventoryItems.inventoryItems[5][6].visible).toBe false

      describe "failure", ->
        beforeEach ->
          $httpBackend.expectPOST('/admin/inventory_items.json',{ enterprise_id: 5, variant_id: 6, visible: null })
          .respond 422, { errors: ["Visible must be true or false"] }
          InventoryItems.setVisibility(5,6,null)

        it "store the errors in the errors object", ->
          expect(InventoryItems.errors).toEqual {}
          $httpBackend.flush()
          expect(InventoryItems.errors[5][6]).toEqual ["Visible must be true or false"]
