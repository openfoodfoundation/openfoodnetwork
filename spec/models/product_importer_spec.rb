require 'spec_helper'
require 'open_food_network/permissions'

describe ProductImporter do
  include AuthenticationWorkflow

  let!(:admin) { create(:admin_user) }
  let!(:user) { create_enterprise_user }
  let!(:user2) { create_enterprise_user }
  let!(:enterprise) { create(:enterprise, owner: user, name: "User Enterprise") }
  let!(:enterprise2) { create(:distributor_enterprise, owner: user2, name: "Another Enterprise") }
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
  let!(:variant_override) { create(:variant_override, variant_id: product4.variants.first.id, hub: enterprise2, count_on_hand: 42) }
  let!(:variant_override2) { create(:variant_override, variant_id: product5.variants.first.id, hub: enterprise, count_on_hand: 96) }

  let(:permissions) { OpenFoodNetwork::Permissions.new(user) }

  describe "importing products from a spreadsheet" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'product_list'})
    end
    after { File.delete('/tmp/test-m.csv') }

    it "returns the number of entries" do
      expect(@importer.item_count).to eq(2)
    end

    it "validates entries and returns the results as json" do
      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 2
      expect(filter('invalid', entries)).to eq 0
      expect(filter('create_product', entries)).to eq 2
      expect(filter('update_product', entries)).to eq 0
    end

    it "saves the results and returns info on updated products" do
      @importer.save_entries

      expect(@importer.products_created_count).to eq 2
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 2

      carrots = Spree::Product.find_by_name('Carrots')
      carrots.supplier.should == enterprise
      carrots.on_hand.should == 5
      carrots.price.should == 3.20
      carrots.variants.first.import_date.should be_within(1.minute).of DateTime.now

      potatoes = Spree::Product.find_by_name('Potatoes')
      potatoes.supplier.should == enterprise
      potatoes.on_hand.should == 6
      potatoes.price.should == 6.50
      potatoes.variants.first.import_date.should be_within(1.minute).of DateTime.now
    end
  end

  describe "when uploading a spreadsheet with some invalid entries" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Good Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Bad Potatoes", "", "Vegetables", "6", "6.50", "1000", "", "1000"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'product_list'})
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
      carrots.supplier.should == enterprise
      carrots.on_hand.should == 5
      carrots.price.should == 3.20
      carrots.variants.first.import_date.should be_within(1.minute).of DateTime.now

      Spree::Product.find_by_name('Bad Potatoes').should == nil
    end
  end

  describe "adding new variants to existing products and updating exiting products" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale", "display_name"]
        csv << ["Hypothetical Cake", "Another Enterprise", "Cake", "5", "5.50", "500", "weight", "1", "Preexisting Banana"]
        csv << ["Hypothetical Cake", "Another Enterprise", "Cake", "6", "3.50", "500", "weight", "1", "Emergent Coffee"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'product_list'})
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
      added_coffee.product.name.should == 'Hypothetical Cake'
      added_coffee.price.should == 3.50
      added_coffee.on_hand.should == 6
      added_coffee.import_date.should be_within(1.minute).of DateTime.now

      updated_banana = Spree::Variant.find_by_display_name('Preexisting Banana')
      updated_banana.product.name.should == 'Hypothetical Cake'
      updated_banana.price.should == 5.50
      updated_banana.on_hand.should == 5
      updated_banana.import_date.should be_within(1.minute).of DateTime.now
    end

  end

  describe "adding new product and sub-variant at the same time" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale", "display_name"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "5", "3.50", "500", "weight", "1000", "Small Bag"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "5.50", "2000", "weight", "1000", "Big Bag"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'product_list'})
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
      small_bag.product.name.should == 'Potatoes'
      small_bag.price.should == 3.50
      small_bag.on_hand.should == 5

      big_bag = Spree::Variant.find_by_display_name('Big Bag')
      big_bag.product.name.should == 'Potatoes'
      big_bag.price.should == 5.50
      big_bag.on_hand.should == 6
    end
  end

  describe "importing items into inventory" do
    before do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "producer", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "6", "6.50", "500"]
        csv << ["Cabbage", "Another Enterprise", "User Enterprise", "Vegetables", "2001", "1.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'inventories'})
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

      Float(beans_override.price).should == 3.20
      beans_override.count_on_hand.should == 5

      Float(sprouts_override.price).should == 6.50
      sprouts_override.count_on_hand.should == 6

      Float(cabbage_override.price).should == 1.50
      cabbage_override.count_on_hand.should == 2001
    end
  end

  describe "handling enterprise permissions" do
    after { File.delete('/tmp/test-m.csv') }

    it "only allows product import into enterprises the user is permitted to manage" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["My Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Your Potatoes", "Another Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, user, {start: 1, end: 100, import_into: 'product_list'})

      @importer.validate_entries
      entries = JSON.parse(@importer.entries_json)

      expect(filter('valid', entries)).to eq 1
      expect(filter('invalid', entries)).to eq 1
      expect(filter('create_product', entries)).to eq 1

      @importer.save_entries

      expect(@importer.products_created_count).to eq 1
      expect(@importer.updated_ids).to be_a(Array)
      expect(@importer.updated_ids.count).to eq 1

      Spree::Product.find_by_name('My Carrots').should be_a Spree::Product
      Spree::Product.find_by_name('Your Potatoes').should == nil
    end

    it "allows creating inventories for producers that a user's hub has permission for" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "supplier", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "User Enterprise", "Another Enterprise", "Vegetables", "777", "3.20", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, user2, {start: 1, end: 100, import_into: 'inventories'})

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
      beans.count_on_hand.should == 777
    end

    it "does not allow creating inventories for producers that a user's hubs don't have permission for" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "User Enterprise", "Vegetables", "6", "6.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, user2, {start: 1, end: 100, import_into: 'inventories'})

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
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Beans", "User Enterprise", "Vegetables", "6", "6.50", "500", "weight", "1"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')

      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'product_list', 'settings' => {enterprise.id => {'reset_all_absent' => true}}})

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

      Spree::Product.find_by_name('Carrots').on_hand.should == 5    # Present in file, added
      Spree::Product.find_by_name('Beans').on_hand.should == 6      # Present in file, updated
      Spree::Product.find_by_name('Sprouts').on_hand.should == 0    # In enterprise, not in file
      Spree::Product.find_by_name('Cabbage').on_hand.should == 0    # In enterprise, not in file
      Spree::Product.find_by_name('Lettuce').on_hand.should == 100  # In different enterprise; unchanged
    end

    it "can reset all inventory items for an enterprise that are not present in the uploaded file to zero stock" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "producer", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "6", "3.20", "500"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "7", "6.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')
      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'inventories', 'settings' => {enterprise2.id => {'reset_all_absent' => true}}})

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

      expect(@importer.products_reset_count).to eq 1

      beans = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      cabbage = VariantOverride.where(variant_id: product4.variants.first.id, hub_id: enterprise2.id).first
      lettuce = VariantOverride.where(variant_id: product5.variants.first.id, hub_id: enterprise.id).first

      beans.count_on_hand.should == 6      # Present in file, created
      sprouts.count_on_hand.should == 7    # Present in file, created
      cabbage.count_on_hand.should == 0    # In enterprise, not in file (reset)
      lettuce.count_on_hand.should == 96   # In different enterprise; unchanged
    end

    it "can overwrite fields with selected defaults when importing to product list" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale", "tax_category_id", "available_on"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1", tax_category.id, ""]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000", "", ""]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')

      import_settings = {enterprise.id.to_s => {
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

      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'product_list', settings: import_settings})

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
      carrots.on_hand.should == 9000
      carrots.tax_category_id.should == tax_category.id
      carrots.shipping_category_id.should == shipping_category.id
      carrots.available_on.should be_within(1.day).of(Time.zone.local(2020, 1, 1))

      potatoes = Spree::Product.find_by_name('Potatoes')
      potatoes.on_hand.should == 9000
      potatoes.tax_category_id.should == tax_category2.id
      potatoes.shipping_category_id.should == shipping_category.id
      potatoes.available_on.should be_within(1.day).of(Time.zone.local(2020, 1, 1))
    end

    it "can overwrite fields with selected defaults when importing to inventory" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "supplier", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "User Enterprise", "Another Enterprise", "Vegetables", "", "3.20", "500"]
        csv << ["Sprouts", "User Enterprise", "Another Enterprise", "Vegetables", "7", "6.50", "500"]
        csv << ["Cabbage", "User Enterprise", "Another Enterprise", "Vegetables", "", "1.50", "500"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')

      import_settings = {enterprise2.id.to_s => {
        'defaults' => {
          'count_on_hand' => {
            'active' => true,
            'mode' => 'overwrite_empty',
            'value' => '9000'
          }
        }
      }}

      @importer = ProductImporter.new(file, admin, {start: 1, end: 100, import_into: 'inventories', settings: import_settings})

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

      beans_override.count_on_hand.should == 9000
      sprouts_override.count_on_hand.should == 7
      cabbage_override.count_on_hand.should == 9000
    end

  end

end

private

def filter(type, entries)
  valid_count = 0
  entries.each do |line_number, entry|
    validates_as = entry['validates_as']

    valid_count += 1 if type == 'valid' and (validates_as != '')
    valid_count += 1 if type == 'invalid' and (validates_as == '')
    valid_count += 1 if type == 'create_product' and (validates_as == 'new_product' or validates_as == 'new_variant')
    valid_count += 1 if type == 'update_product' and validates_as == 'existing_variant'
    valid_count += 1 if type == 'create_inventory' and validates_as == 'new_inventory_item'
    valid_count += 1 if type == 'update_inventory' and validates_as == 'existing_inventory_item'
  end
  valid_count
end