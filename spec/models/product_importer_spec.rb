require 'spec_helper'
require 'open_food_network/permissions'

describe ProductImport::ProductImporter do
  include AuthenticationWorkflow

  let!(:admin) { create(:admin_user) }
  let!(:user) { create_enterprise_user }
  let!(:user2) { create_enterprise_user }
  let!(:user3) { create_enterprise_user }
  let!(:enterprise) { create(:enterprise, owner: user, name: "User Enterprise") }
  let!(:enterprise2) { create(:distributor_enterprise, owner: user2, name: "Another Enterprise") }
  let!(:enterprise3) { create(:distributor_enterprise, owner: user3, name: "And Another Enterprise") }
  let!(:relationship) { create(:enterprise_relationship, parent: enterprise, child: enterprise2, permissions_list: [:create_variant_overrides]) }

  let!(:category) { create(:taxon, name: 'Vegetables') }
  let!(:category2) { create(:taxon, name: 'Cake') }
  let!(:tax_category) { create(:tax_category) }
  let!(:tax_category2) { create(:tax_category) }
  let!(:shipping_category) { create(:shipping_category) }

  let!(:product) { create(:simple_product, supplier: enterprise2, name: 'Hypothetical Cake') }
  let!(:variant) { create(:variant, product_id: product.id, price: '8.50', on_hand: '100', unit_value: '500', display_name: 'Preexisting Banana') }
  let!(:product2) { create(:simple_product, supplier: enterprise, on_hand: '100', name: 'Beans', unit_value: '500') }
  let!(:product3) { create(:simple_product, supplier: enterprise, on_hand: '100', name: 'Sprouts', unit_value: '500') }
  let!(:product4) { create(:simple_product, supplier: enterprise, on_hand: '100', name: 'Cabbage', unit_value: '500') }
  let!(:product5) { create(:simple_product, supplier: enterprise2, on_hand: '100', name: 'Lettuce', unit_value: '500') }
  let!(:product6) { create(:simple_product, supplier: enterprise3, on_hand: '100', name: 'Beetroot', unit_value: '500', on_demand: true, variant_unit_scale: 1, variant_unit: 'weight') }
  let!(:product7) { create(:simple_product, supplier: enterprise3, on_hand: '100', name: 'Tomato', unit_value: '500', variant_unit_scale: 1, variant_unit: 'weight') }
  let!(:variant_override) { create(:variant_override, variant_id: product4.variants.first.id, hub: enterprise2, count_on_hand: 42) }
  let!(:variant_override2) { create(:variant_override, variant_id: product5.variants.first.id, hub: enterprise, count_on_hand: 96) }

  let(:permissions) { OpenFoodNetwork::Permissions.new(user) }

  describe "importing products from a spreadsheet" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type", "variant_unit_name", "on_demand"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", "", ""]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "2", "kg", "", ""]
        csv << ["Pea Soup", "User Enterprise", "Vegetables", "8", "5.50", "750", "ml", "", "0"]
        csv << ["Salad", "User Enterprise", "Vegetables", "7", "4.50", "1", "", "bags", ""]
        csv << ["Hot Cross Buns", "User Enterprise", "Cake", "7", "3.50", "1", "", "buns", "1"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise.id.to_s => {'import_into' => 'product_list'}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)
    end
    after { File.delete('/tmp/test-m.csv') }

    it "returns the number of entries" do
      expect(@importer.item_count).to eq(5)
    end

    it "validates entries and returns the results as json" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 5
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_product', entries)).to eq 5
      expect(filter('update_product', entries)).to eq 0
    end

    it "saves the results and returns info on updated products" do
      @importer.save_entries

      expect(@importer.products_created_count).to eq 5
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 5

      carrots = Spree::Product.find_by_name('Carrots')
      expect(carrots.supplier).to eq enterprise
      expect(carrots.on_hand).to eq 5
      expect(carrots.price).to eq 3.20
      expect(carrots.unit_value).to eq 500
      expect(carrots.variant_unit).to eq 'weight'
      expect(carrots.variant_unit_scale).to eq 1
      expect(carrots.on_demand).to_not eq true
      expect(carrots.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      potatoes = Spree::Product.find_by_name('Potatoes')
      expect(potatoes.supplier).to eq enterprise
      expect(potatoes.on_hand).to eq 6
      expect(potatoes.price).to eq 6.50
      expect(potatoes.unit_value).to eq 2000
      expect(potatoes.variant_unit).to eq 'weight'
      expect(potatoes.variant_unit_scale).to eq 1000
      expect(potatoes.on_demand).to_not eq true
      expect(potatoes.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      pea_soup = Spree::Product.find_by_name('Pea Soup')
      expect(pea_soup.supplier).to eq enterprise
      expect(pea_soup.on_hand).to eq 8
      expect(pea_soup.price).to eq 5.50
      expect(pea_soup.unit_value).to eq 0.75
      expect(pea_soup.variant_unit).to eq 'volume'
      expect(pea_soup.variant_unit_scale).to eq 0.001
      expect(pea_soup.on_demand).to_not eq true
      expect(pea_soup.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      salad = Spree::Product.find_by_name('Salad')
      expect(salad.supplier).to eq enterprise
      expect(salad.on_hand).to eq 7
      expect(salad.price).to eq 4.50
      expect(salad.unit_value).to eq 1
      expect(salad.variant_unit).to eq 'items'
      expect(salad.variant_unit_scale).to eq nil
      expect(salad.on_demand).to_not eq true
      expect(salad.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      buns = Spree::Product.find_by_name('Hot Cross Buns')
      expect(buns.supplier).to eq enterprise
      # buns.on_hand).to eq Infinity
      expect(buns.price).to eq 3.50
      expect(buns.unit_value).to eq 1
      expect(buns.variant_unit).to eq 'items'
      expect(buns.variant_unit_scale).to eq nil
      expect(buns.on_demand).to eq true
      expect(buns.variants.first.import_date).to be_within(1.minute).of Time.zone.now
    end
  end

  describe "when uploading a spreadsheet with some invalid entries" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["Good Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g"]
        csv << ["Bad Potatoes", "", "Vegetables", "6", "6.50", "1", ""]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise.id.to_s => {'import_into' => 'product_list'}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)
    end
    after { File.delete('/tmp/test-m.csv') }

    it "validates entries" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 1
      expect(filter('invalid', entries)).to eq 1
      expect(filter('create_product', entries)).to eq 1
      expect(filter('update_product', entries)).to eq 0
    end

    it "allows saving of the valid entries" do
      @importer.save_entries

      expect(@importer.products_created_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 1

      carrots = Spree::Product.find_by_name('Good Carrots')
      expect(carrots.supplier).to eq enterprise
      expect(carrots.on_hand).to eq 5
      expect(carrots.price).to eq 3.20
      expect(carrots.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      expect(Spree::Product.find_by_name('Bad Potatoes')).to eq nil
    end
  end

  describe "adding new variants to existing products and updating exiting products" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type", "display_name"]
        csv << ["Hypothetical Cake", "Another Enterprise", "Cake", "5", "5.50", "500", "g", "Preexisting Banana"]
        csv << ["Hypothetical Cake", "Another Enterprise", "Cake", "6", "3.50", "500", "g", "Emergent Coffee"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise2.id.to_s => {'import_into' => 'product_list'}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)
    end
    after { File.delete('/tmp/test-m.csv') }

    it "validates entries" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 2
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_product', entries)).to eq 1
      expect(filter('update_product', entries)).to eq 1
    end

    it "saves and updates" do
      @importer.save_entries

      expect(@importer.products_created_count).to eq 1
      expect(@importer.products_updated_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 2

      added_coffee = Spree::Variant.find_by_display_name('Emergent Coffee')
      expect(added_coffee.product.name).to eq 'Hypothetical Cake'
      expect(added_coffee.price).to eq 3.50
      expect(added_coffee.on_hand).to eq 6
      expect(added_coffee.import_date).to be_within(1.minute).of Time.zone.now

      updated_banana = Spree::Variant.find_by_display_name('Preexisting Banana')
      expect(updated_banana.product.name).to eq 'Hypothetical Cake'
      expect(updated_banana.price).to eq 5.50
      expect(updated_banana.on_hand).to eq 5
      expect(updated_banana.import_date).to be_within(1.minute).of Time.zone.now
    end
  end

  describe "adding new product and sub-variant at the same time" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type", "display_name"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "5", "3.50", "500", "g", "Small Bag"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "5.50", "2", "kg", "Big Bag"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise.id.to_s => {'import_into' => 'product_list'}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)
    end
    after { File.delete('/tmp/test-m.csv') }

    it "validates entries" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 2
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_product', entries)).to eq 2
    end

    it "saves and updates" do
      @importer.save_entries

      expect(@importer.products_created_count).to eq 2
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 2

      small_bag = Spree::Variant.find_by_display_name('Small Bag')
      expect(small_bag.product.name).to eq 'Potatoes'
      expect(small_bag.price).to eq 3.50
      expect(small_bag.on_hand).to eq 5

      big_bag = Spree::Variant.find_by_display_name('Big Bag')
      expect(big_bag.product.name).to eq 'Potatoes'
      expect(big_bag.price).to eq 5.50
      expect(big_bag.on_hand).to eq 6
    end
  end

  describe "updating various fields" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type", "on_demand"]
        csv << ["Beetroot", "And Another Enterprise", "Vegetables", "5", "3.50", "500", "g", "0"]
        csv << ["Tomato", "And Another Enterprise", "Vegetables", "6", "5.50", "500", "g", "1"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise3.id.to_s => {'import_into' => 'product_list'}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)
    end
    after { File.delete('/tmp/test-m.csv') }

    it "validates entries" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 2
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_product', entries)).to eq 0
      expect(filter('update_product', entries)).to eq 2
    end

    it "saves and updates" do
      @importer.save_entries

      expect(@importer.products_created_count).to eq 0
      expect(@importer.products_updated_count).to eq 2
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 2

      beetroot = Spree::Product.find_by_name('Beetroot').variants.first
      expect(beetroot.price).to eq 3.50
      expect(beetroot.on_demand).to_not eq true

      tomato = Spree::Product.find_by_name('Tomato').variants.first
      expect(tomato.price).to eq 5.50
      expect(tomato.on_demand).to eq true
    end
  end

  describe "importing items into inventory" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "producer", "category", "on_hand", "price", "units"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "6", "6.50", "500"]
        csv << ["Cabbage", "Another Enterprise", "User Enterprise", "Vegetables", "2001", "1.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise2.id.to_s => {'import_into' => 'inventories'}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)
    end
    after { File.delete('/tmp/test-m.csv') }

    it "validates entries" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 3
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_inventory', entries)).to eq 2
      expect(filter('update_inventory', entries)).to eq 1
    end

    it "saves and updates inventory" do
      @importer.save_entries

      expect(@importer.inventory_created_count).to eq 2
      expect(@importer.inventory_updated_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 3

      beans_override = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts_override = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      cabbage_override = VariantOverride.where(variant_id: product4.variants.first.id, hub_id: enterprise2.id).first

      expect(Float(beans_override.price)).to eq 3.20
      expect(beans_override.count_on_hand).to eq 5

      expect(Float(sprouts_override.price)).to eq 6.50
      expect(sprouts_override.count_on_hand).to eq 6

      expect(Float(cabbage_override.price)).to eq 1.50
      expect(cabbage_override.count_on_hand).to eq 2001
    end
  end

  describe "importing items into inventory and product list simultaneously" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "producer", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "5", "3.20", "500", ""]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "6", "6.50", "500", ""]
        csv << ["Garbanzos", "User Enterprise", "", "Vegetables", "2001", "1.50", "500", "g"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise.id.to_s => {'import_into' => 'product_list'}, enterprise2.id.to_s => {'import_into' => 'inventories'}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)
    end
    after { File.delete('/tmp/test-m.csv') }

    it "validates entries" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 3
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_inventory', entries)).to eq 2
      expect(filter('create_product', entries)).to eq 1
    end

    it "saves and updates inventory" do
      @importer.save_entries

      expect(@importer.inventory_created_count).to eq 2
      expect(@importer.products_created_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 3

      beans_override = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts_override = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      garbanzos = Spree::Product.where(name: "Garbanzos").first

      expect(Float(beans_override.price)).to eq 3.20
      expect( beans_override.count_on_hand).to eq 5

      expect(Float(sprouts_override.price)).to eq 6.50
      expect(sprouts_override.count_on_hand).to eq 6

      expect(Float(garbanzos.price)).to eq 1.50
      expect(garbanzos.count_on_hand).to eq 2001
    end
  end

  describe "handling enterprise permissions" do
    after { File.delete('/tmp/test-m.csv') }

    it "only allows product import into enterprises the user is permitted to manage" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["My Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g"]
        csv << ["Your Potatoes", "Another Enterprise", "Vegetables", "6", "6.50", "1", "kg"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise.id.to_s => {'import_into' => 'product_list'}, enterprise2.id.to_s => {'import_into' => 'product_list'}}
      @importer = ProductImport::ProductImporter.new(file, user, start: 1, end: 100, settings: settings)

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 1
      expect(filter('invalid', entries)).to eq 1
      expect(filter('create_product', entries)).to eq 1

      @importer.save_entries

      expect(@importer.products_created_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 1

      expect(Spree::Product.find_by_name('My Carrots')).to be_a Spree::Product
      expect(Spree::Product.find_by_name('Your Potatoes')).to eq nil
    end

    it "allows creating inventories for producers that a user's hub has permission for" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "supplier", "category", "on_hand", "price", "units"]
        csv << ["Beans", "User Enterprise", "Another Enterprise", "Vegetables", "777", "3.20", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise2.id.to_s => {'import_into' => 'inventories'}}
      @importer = ProductImport::ProductImporter.new(file, user2, start: 1, end: 100, settings: settings)

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 1
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_inventory', entries)).to eq 1

      @importer.save_entries

      expect(@importer.inventory_created_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 1

      beans = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      expect(beans.count_on_hand).to eq 777
    end

    it "does not allow creating inventories for producers that a user's hubs don't have permission for" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units"]
        csv << ["Beans", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "User Enterprise", "Vegetables", "6", "6.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise.id.to_s => {'import_into' => 'inventories'}}
      @importer = ProductImport::ProductImporter.new(file, user2, start: 1, end: 100, settings: settings)

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 0
      expect(filter('invalid', entries)).to eq 2
      expect(filter('create_inventory', entries)).to eq 0

      @importer.save_entries

      expect(@importer.inventory_created_count).to eq 0
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 0
    end
  end

  describe "applying settings and defaults on import" do
    after { File.delete('/tmp/test-m.csv') }

    it "can reset all products for an enterprise that are not present in the uploaded file to zero stock" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g"]
        csv << ["Beans", "User Enterprise", "Vegetables", "6", "6.50", "500", "g"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise.id.to_s => {'import_into' => 'product_list', 'reset_all_absent' => true}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 2
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_product', entries)).to eq 1
      expect(filter('update_product', entries)).to eq 1

      @importer.save_entries

      expect(@importer.products_created_count).to eq 1
      expect(@importer.products_updated_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 2

      @importer.reset_absent(@importer.updated_ids)

      expect(@importer.products_reset_count).to eq 2

      expect(Spree::Product.find_by_name('Carrots').on_hand).to eq 5    # Present in file, added
      expect(Spree::Product.find_by_name('Beans').on_hand).to eq 6      # Present in file, updated
      expect(Spree::Product.find_by_name('Sprouts').on_hand).to eq 0    # In enterprise, not in file
      expect(Spree::Product.find_by_name('Cabbage').on_hand).to eq 0    # In enterprise, not in file
      expect(Spree::Product.find_by_name('Lettuce').on_hand).to eq 100  # In different enterprise; unchanged
    end

    it "can reset all inventory items for an enterprise that are not present in the uploaded file to zero stock" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "producer", "category", "on_hand", "price", "units"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "6", "3.20", "500"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "7", "6.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      settings = {enterprise2.id.to_s => {'import_into' => 'inventories', 'reset_all_absent' => true}}
      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 2
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_inventory', entries)).to eq 2

      @importer.save_entries

      expect(@importer.inventory_created_count).to eq 2
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 2

      @importer.reset_absent(@importer.updated_ids)

      # expect(@importer.products_reset_count).to eq 1

      beans = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      cabbage = VariantOverride.where(variant_id: product4.variants.first.id, hub_id: enterprise2.id).first
      lettuce = VariantOverride.where(variant_id: product5.variants.first.id, hub_id: enterprise.id).first

      expect(beans.count_on_hand).to eq 6      # Present in file, created
      expect(sprouts.count_on_hand).to eq 7    # Present in file, created
      expect(cabbage.count_on_hand).to eq 0    # In enterprise, not in file (reset)
      expect(lettuce.count_on_hand).to eq 96   # In different enterprise; unchanged
    end

    it "can overwrite fields with selected defaults when importing to product list" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type", "tax_category_id", "available_on"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", tax_category.id, ""]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1", "kg", "", ""]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')

      settings = {enterprise.id.to_s => {
        'import_into' => 'product_list',
        'defaults' => {
          'on_hand' => {
            'active' => true,
            'mode' => 'overwrite_all',
            'value' => '9000'
          },
          'tax_category_id' => {
            'active' => true,
            'mode' => 'overwrite_empty',
            'value' => tax_category2.id
          },
          'shipping_category_id' => {
            'active' => true,
            'mode' => 'overwrite_all',
            'value' => shipping_category.id
          },
          'available_on' => {
            'active' => true,
            'mode' => 'overwrite_all',
            'value' => '2020-01-01'
          }
        }
      }}

      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, settings: settings)

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 2
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_product', entries)).to eq 2

      @importer.save_entries

      expect(@importer.products_created_count).to eq 2
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 2

      carrots = Spree::Product.find_by_name('Carrots')
      expect(carrots.on_hand).to eq 9000
      expect(carrots.tax_category_id).to eq tax_category.id
      expect(carrots.shipping_category_id).to eq shipping_category.id
      expect(carrots.available_on).to be_within(1.day).of(Time.zone.local(2020, 1, 1))

      potatoes = Spree::Product.find_by_name('Potatoes')
      expect(potatoes.on_hand).to eq 9000
      expect(potatoes.tax_category_id).to eq tax_category2.id
      expect(potatoes.shipping_category_id).to eq shipping_category.id
      expect(potatoes.available_on).to be_within(1.day).of(Time.zone.local(2020, 1, 1))
    end

    it "can overwrite fields with selected defaults when importing to inventory" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "supplier", "category", "on_hand", "price", "units"]
        csv << ["Beans", "User Enterprise", "Another Enterprise", "Vegetables", "", "3.20", "500"]
        csv << ["Sprouts", "User Enterprise", "Another Enterprise", "Vegetables", "7", "6.50", "500"]
        csv << ["Cabbage", "User Enterprise", "Another Enterprise", "Vegetables", "", "1.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')

      import_settings = {enterprise2.id.to_s => {
        'import_into' => 'inventories',
        'defaults' => {
          'count_on_hand' => {
            'active' => true,
            'mode' => 'overwrite_empty',
            'value' => '9000'
          }
        }
      }}

      @importer = ProductImport::ProductImporter.new(file, admin, start: 1, end: 100, import_into: 'inventories', settings: import_settings)

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 3
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_inventory', entries)).to eq 2
      expect(filter('update_inventory', entries)).to eq 1

      @importer.save_entries

      expect(@importer.inventory_created_count).to eq 2
      expect(@importer.inventory_updated_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 3

      beans_override = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts_override = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      cabbage_override = VariantOverride.where(variant_id: product4.variants.first.id, hub_id: enterprise2.id).first

      expect(beans_override.count_on_hand).to eq 9000
      expect(sprouts_override.count_on_hand).to eq 7
      expect(cabbage_override.count_on_hand).to eq 9000
    end
  end
end

private

def filter(type, entries)
  valid_count = 0
  entries.each do |_line_number, entry|
    validates_as = entry['validates_as']

    valid_count += 1 if type == 'valid' && (validates_as != '')
    valid_count += 1 if type == 'invalid' && (validates_as == '')
    valid_count += 1 if type == 'create_product' && (validates_as == 'new_product' || validates_as == 'new_variant')
    valid_count += 1 if type == 'update_product' && validates_as == 'existing_variant'
    valid_count += 1 if type == 'create_inventory' && validates_as == 'new_inventory_item'
    valid_count += 1 if type == 'update_inventory' && validates_as == 'existing_inventory_item'
  end
  valid_count
end
