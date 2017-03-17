require 'spec_helper'
require 'open_food_network/permissions'

feature "Product Import", js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:admin) { create(:admin_user) }
  let!(:user) { create_enterprise_user }
  let!(:user2) { create_enterprise_user }
  let!(:enterprise) { create(:supplier_enterprise, owner: user, name: "User Enterprise") }
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

  describe "when importing products from uploaded file" do
    before { quick_login_as_admin }
    after { File.delete('/tmp/test.csv') }

    it "validates entries and saves them if they are all valid" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "2"
      expect(page).to_not have_selector '.update-count'

      click_button 'Save'
      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to_not have_selector '.updated-count'

      potatoes = Spree::Product.find_by_name('Potatoes')
      potatoes.supplier.should == enterprise
      potatoes.on_hand.should == 6
      potatoes.price.should == 6.50
      potatoes.variants.first.import_date.should be_within(1.minute).of DateTime.now
    end

    it "displays info about invalid entries but still allows saving of valid entries" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Good Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Bad Potatoes", "", "Vegetables", "6", "6.50", "1000", "", "1000"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file('file', '/tmp/test.csv')
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"

      expect(page).to have_selector 'input[type=submit][value="Save"]'
      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '1'

      Spree::Product.find_by_name('Bad Potatoes').should == nil
      carrots = Spree::Product.find_by_name('Good Carrots')
      carrots.supplier.should == enterprise
      carrots.on_hand.should == 5
      carrots.price.should == 3.20
    end

    it "displays info about invalid entries but no save button if all items are invalid" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Bad Carrots", "Unkown Enterprise", "Mouldy vegetables", "666", "3.20", "", "weight", ""]
        csv << ["Bad Potatoes", "", "Vegetables", "6", "6", "6", "", "1000"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "2"
      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'

      expect(page).to_not have_selector 'input[type=submit][value="Save"]'
    end

    it "can add new variants to existing products and update price and stock level of existing products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale", "display_name"]
        csv << ["Hypothetical Cake", "Another Enterprise", "Cake", "5", "5.50", "500", "weight", "1", "Preexisting Banana"]
        csv << ["Hypothetical Cake", "Another Enterprise", "Cake", "6", "3.50", "500", "weight", "1", "Emergent Coffee"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "1"
      expect(page).to have_selector '.update-count', text: "1"

      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_selector '.updated-count', text: '1'

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

    it "can add a new product and sub-variants of that product at the same time" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale", "display_name"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "5", "3.50", "500", "weight", "1000", "Small Bag"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "5.50", "2000", "weight", "1000", "Big Bag"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "2"

      click_button 'Save'
      expect(page).to have_selector '.created-count', text: '2'

      small_bag = Spree::Variant.find_by_display_name('Small Bag')
      small_bag.product.name.should == 'Potatoes'
      small_bag.price.should == 3.50
      small_bag.on_hand.should == 5

      big_bag = Spree::Variant.find_by_display_name('Big Bag')
      big_bag.product.name.should == 'Potatoes'
      big_bag.price.should == 5.50
      big_bag.on_hand.should == 6
    end

    it "records a timestamp on import that can be viewed and filtered under Bulk Edit Products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'
      click_button 'Save'

      carrots = Spree::Product.find_by_name('Carrots')
      carrots.variants.first.import_date.should be_within(1.minute).of DateTime.now

      visit 'admin/products/bulk_edit'

      wait_until { page.find("#p_#{carrots.id}").present? }

      expect(page).to have_field "product_name", with: carrots.name
      find("div#columns-dropdown", :text => "COLUMNS").click
      find("div#columns-dropdown div.menu div.menu_item", text: "Import").click
      find("div#columns-dropdown", :text => "COLUMNS").click

      within "tr#p_#{carrots.id} td.import_date" do
        expect(page).to have_content DateTime.now.year
      end

      expect(page).to have_selector 'div#s2id_import_date_filter'
      import_time = carrots.import_date.to_formatted_s(:long)
      select import_time, from: "import_date_filter", visible: false

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to_not have_field "product_name", with: product.name
      expect(page).to_not have_field "product_name", with: product2.name
    end

    it "can import items into inventory" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "producer", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "6", "6.50", "500"]
        csv << ["Cabbage", "Another Enterprise", "User Enterprise", "Vegetables", "2001", "1.50", "500"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      select 'Inventories', from: "settings_import_into", visible: false
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'
      expect(page).to have_selector '.inv-create-count', text: "2"
      expect(page).to have_selector '.inv-update-count', text: "1"

      click_button 'Save'

      expect(page).to_not have_selector '.created-count'
      expect(page).to_not have_selector '.updated-count'
      expect(page).to have_selector '.inv-created-count', text: '2'
      expect(page).to have_selector '.inv-updated-count', text: '1'


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

  describe "when dealing with uploaded files" do
    before { quick_login_as_admin }

    it "checks filetype on upload" do
      File.write('/tmp/test.txt', "Wrong filetype!")

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.txt'
      click_button 'Import'

      expect(page).to have_content "Importer could not process file: invalid filetype"
      expect(page).to_not have_selector 'input[type=submit][value="Save"]'
      expect(page).to have_content "Select a spreadsheet to upload"
      File.delete('/tmp/test.txt')
    end

    it "returns and error if nothing was uploaded" do
      visit main_app.admin_product_import_path
      expect(page).to have_content 'Select a spreadsheet to upload'
      click_button 'Import'

      expect(flash_message).to eq I18n.t(:product_import_file_not_found_notice)
    end

    it "handles cases where no meaningful data can be read from the file" do
      File.write('/tmp/test.csv', "A22££S\\\\\n**VA,,,AF..D")

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'
      expect(page).to_not have_selector 'input[type=submit][value="Save"]'
      File.delete('/tmp/test.csv')
    end
  end

  describe "handling enterprise permissions" do
    after { File.delete('/tmp/test.csv') }

    it "only allows product import into enterprises the user is permitted to manage" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["My Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Your Potatoes", "Another Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test.csv', csv_data)

      quick_login_as user
      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"

      expect(page.body).to have_content 'you do not have permission'

      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '1'

      Spree::Product.find_by_name('My Carrots').should be_a Spree::Product
      Spree::Product.find_by_name('Your Potatoes').should == nil
    end

    it "allows creating inventories for producers that a user's hub has permission for" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "supplier", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "User Enterprise", "Another Enterprise", "Vegetables", "777", "3.20", "500"]
      end
      File.write('/tmp/test.csv', csv_data)

      quick_login_as user2
      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      select 'Inventories', from: "settings_import_into", visible: false
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "1"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.inv-create-count', text: "1"

      #expect(page.body).to have_content 'you do not have permission'

      click_button 'Save'

      expect(page).to have_selector '.inv-created-count', text: '1'

      beans = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      beans.count_on_hand.should == 777
    end

    it "does not allow creating inventories for producers that a user's hubs don't have permission for" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value"]
        csv << ["Beans", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "User Enterprise", "Vegetables", "6", "6.50", "500"]
      end
      File.write('/tmp/test.csv', csv_data)

      quick_login_as user2
      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      select 'Inventories', from: "settings_import_into", visible: false
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "2"
      expect(page).to_not have_selector '.inv-create-count'

      expect(page.body).to have_content 'you do not have permission'


    end
  end

  describe "applying settings and defaults on import" do
    before { quick_login_as_admin }
    after { File.delete('/tmp/test.csv') }

    it "can reset all products for an enterprise that are not present in the uploaded file to zero stock" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Beans", "User Enterprise", "Vegetables", "6", "6.50", "500", "weight", "1"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "1"
      expect(page).to have_selector '.update-count', text: "1"

      expect(page).to_not have_selector '.reset-count'

      within 'div.import-settings' do
        find('div.header-description').click  # Import settings tab
        check "settings_#{enterprise.id}_reset_all_absent"
      end

      expect(page).to have_selector '.reset-count', text: "2"

      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_selector '.updated-count', text: '1'
      expect(page).to have_selector '.reset-count', text: '2'

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
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      select 'Inventories', from: "settings_import_into", visible: false
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.inv-create-count', text: "2"

      expect(page).to_not have_selector '.reset-count'

      within 'div.import-settings' do
        find('div.header-description').click  # Import settings tab
        check "settings_#{enterprise2.id}_reset_all_absent"
      end

      expect(page).to have_selector '.reset-count', text: "1"

      click_button 'Save'

      expect(page).to have_selector '.inv-created-count', text: '2'
      expect(page).to have_selector '.reset-count', text: '1'

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
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      within 'div.import-settings' do
        find('div.header-description').click  # Import settings tab
        expect(page).to have_selector "#settings_#{enterprise.id}_defaults_on_hand_mode", visible: false

        # Overwrite stock level of all items to 9000
        check "settings_#{enterprise.id}_defaults_on_hand_active"
        select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_on_hand_mode", visible: false
        fill_in "settings_#{enterprise.id}_defaults_on_hand_value", with: '9000'

        # Overwrite default tax category, but only where field is empty
        check "settings_#{enterprise.id}_defaults_tax_category_id_active"
        select 'Overwrite if empty', from: "settings_#{enterprise.id}_defaults_tax_category_id_mode", visible: false
        select tax_category2.name, from: "settings_#{enterprise.id}_defaults_tax_category_id_value", visible: false

        # Set default shipping category (field not present in file)
        check "settings_#{enterprise.id}_defaults_shipping_category_id_active"
        select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_shipping_category_id_mode", visible: false
        select shipping_category.name, from: "settings_#{enterprise.id}_defaults_shipping_category_id_value", visible: false

        # Set available_on date
        check "settings_#{enterprise.id}_defaults_available_on_active"
        select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_available_on_mode", visible: false
        find("input#settings_#{enterprise.id}_defaults_available_on_value").set '2020-01-01'
      end

      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '2'

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
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      select 'Inventories', from: "settings_import_into", visible: false
      click_button 'Import'

      within 'div.import-settings' do
        find('div.header-description').click  # Import settings tab
        check "settings_#{enterprise2.id}_defaults_count_on_hand_active"
        select 'Overwrite if empty', from: "settings_#{enterprise2.id}_defaults_count_on_hand_mode", visible: false
        fill_in "settings_#{enterprise2.id}_defaults_count_on_hand_value", with: '9000'
      end

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'
      expect(page).to have_selector '.inv-create-count', text: "2"
      expect(page).to have_selector '.inv-update-count', text: "1"

      click_button 'Save'

      expect(page).to_not have_selector '.created-count'
      expect(page).to_not have_selector '.updated-count'
      expect(page).to have_selector '.inv-created-count', text: '2'
      expect(page).to have_selector '.inv-updated-count', text: '1'

      beans_override = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts_override = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      cabbage_override = VariantOverride.where(variant_id: product4.variants.first.id, hub_id: enterprise2.id).first

      beans_override.count_on_hand.should == 9000
      sprouts_override.count_on_hand.should == 7
      cabbage_override.count_on_hand.should == 9000
    end
  end
end
