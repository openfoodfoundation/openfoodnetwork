require 'spec_helper'
require 'open_food_network/permissions'

feature "Product Import", js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:admin) { create(:admin_user) }
  let!(:user) { create_enterprise_user }
  let!(:enterprise) { create(:supplier_enterprise, owner: user, name: "User Enterprise") }
  let!(:enterprise2) { create(:supplier_enterprise, owner: admin, name: "Another Enterprise") }
  let!(:category) { create(:taxon, name: 'Vegetables') }
  let!(:category2) { create(:taxon, name: 'Cake') }
  let!(:tax_category) { create(:tax_category) }
  let!(:tax_category2) { create(:tax_category) }
  let!(:shipping_category) { create(:shipping_category) }
  let!(:product) { create(:simple_product, supplier: enterprise2, name: 'Hypothetical Cake') }
  let!(:variant) { create(:variant, product_id: product.id, price: '8.50', on_hand: '100', unit_value: '500', display_name: 'Preexisting Banana') }
  let!(:product2) { create(:simple_product, supplier: enterprise, on_hand: '100', name: 'Beans', unit_value: '500') }
  let!(:product3) { create(:simple_product, supplier: enterprise, on_hand: '100', name: 'Sprouts') }
  let!(:product4) { create(:simple_product, supplier: enterprise, on_hand: '100', name: 'Cabbage') }
  let!(:product5) { create(:simple_product, supplier: enterprise2, on_hand: '100', name: 'Lettuce') }


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
      expect(page).to have_selector '.invalid-count', text: "0"
      expect(page).to have_selector '.create-count', text: "2"
      expect(page).to have_selector '.update-count', text: "0"

      click_button 'Save'
      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to have_selector '.updated-count', text: '0'

      potatoes = Spree::Product.find_by_name('Potatoes')
      expect(potatoes.supplier).to eq(enterprise)
      expect(potatoes.on_hand).to eq(6)
      expect(potatoes.price).to eq(6.50)
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
      expect(page).to have_selector '.update-count', text: "0"

      expect(page).to have_selector 'input[type=submit][value="Save"]'
      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_selector '.updated-count', text: '0'

      expect(Spree::Product.find_by_name('Bad Potatoes')).to eq(nil)
      carrots = Spree::Product.find_by_name('Good Carrots')
      expect(carrots.supplier).to eq(enterprise)
      expect(carrots.on_hand).to eq(5)
      expect(carrots.price).to eq(3.20)
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
      expect(page).to have_selector '.create-count', text: "0"
      expect(page).to have_selector '.update-count', text: "0"

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
      expect(page).to have_selector '.invalid-count', text: "0"
      expect(page).to have_selector '.create-count', text: "1"
      expect(page).to have_selector '.update-count', text: "1"

      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_selector '.updated-count', text: '1'

      added_coffee = Spree::Variant.find_by_display_name('Emergent Coffee')
      expect(added_coffee.product.name).to eq('Hypothetical Cake')
      expect(added_coffee.price).to eq(3.50)
      expect(added_coffee.on_hand).to eq(6)

      updated_banana = Spree::Variant.find_by_display_name('Preexisting Banana')
      expect(updated_banana.product.name).to eq('Hypothetical Cake')
      expect(updated_banana.price).to eq(5.50)
      expect(updated_banana.on_hand).to eq(5)
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
      expect(page).to have_selector '.invalid-count', text: "0"
      expect(page).to have_selector '.create-count', text: "2"
      expect(page).to have_selector '.update-count', text: "0"

      click_button 'Save'
      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to have_selector '.updated-count', text: '0'

      small_bag = Spree::Variant.find_by_display_name('Small Bag')
      expect(small_bag.product.name).to eq('Potatoes')
      expect(small_bag.price).to eq(3.50)
      expect(small_bag.on_hand).to eq(5)

      big_bag = Spree::Variant.find_by_display_name('Big Bag')
      expect(big_bag.product.name).to eq('Potatoes')
      expect(big_bag.price).to eq(5.50)
      expect(big_bag.on_hand).to eq(6)
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

      expect(page).to have_selector '.create-count', text: "0"
      expect(page).to have_selector '.update-count', text: "0"
      expect(page).to_not have_selector 'input[type=submit][value="Save"]'
      File.delete('/tmp/test.csv')
    end
  end

  describe "handling enterprise permissions" do
    before { quick_login_as user }

    it "only allows import into enterprises the user is permitted to manage" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["My Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Your Potatoes", "Another Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      click_button 'Import'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"
      expect(page).to have_selector '.update-count', text: "0"

      expect(page.body).to have_content 'you do not have permission'

      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_selector '.updated-count', text: '0'

      expect(Spree::Product.find_by_name('My Carrots')).to be_a Spree::Product
      expect(Spree::Product.find_by_name('Your Potatoes')).to eq(nil)
    end
  end

  describe "applying settings and defaults on import" do
    before { quick_login_as_admin }

    it "can set all products for an enterprise that are not present in the uploaded file to zero stock" do
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
      expect(page).to have_selector '.invalid-count', text: "0"
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

      expect(Spree::Product.find_by_name('Carrots').on_hand).to eq(5)    # Present in file, added
      expect(Spree::Product.find_by_name('Beans').on_hand).to eq(6)      # Present in file, updated
      expect(Spree::Product.find_by_name('Sprouts').on_hand).to eq(0)    # In enterprise, not in file
      expect(Spree::Product.find_by_name('Cabbage').on_hand).to eq(0)    # In enterprise, not in file
      expect(Spree::Product.find_by_name('Lettuce').on_hand).to eq(100)  # In different enterprise; unchanged
    end

    it "overwrites fields with selected defaults" do
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
        select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_on_hand_mode", visible: false
        fill_in "settings_#{enterprise.id}_defaults_on_hand_value", with: '9000'

        # Overwrite default tax category, but only where field is empty
        select 'Overwrite if empty', from: "settings_#{enterprise.id}_defaults_tax_category_id_mode", visible: false
        select tax_category2.name, from: "settings_#{enterprise.id}_defaults_tax_category_id_value", visible: false

        # Set default shipping category (field not present in file)
        select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_shipping_category_id_mode", visible: false
        select shipping_category.name, from: "settings_#{enterprise.id}_defaults_shipping_category_id_value", visible: false

        # Set available_on date
        select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_available_on_mode", visible: false
        find("input#settings_#{enterprise.id}_defaults_available_on_value").set '2020-01-01'
      end

      click_button 'Save'

      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to have_selector '.updated-count', text: '0'

      carrots = Spree::Product.find_by_name('Carrots')
      expect(carrots.on_hand).to eq(9000)
      expect(carrots.tax_category_id).to eq(tax_category.id)
      expect(carrots.shipping_category_id).to eq(shipping_category.id)
      expect(carrots.available_on).to be_within(1.day).of(Time.zone.local(2020, 1, 1))

      potatoes = Spree::Product.find_by_name('Potatoes')
      expect(potatoes.on_hand).to eq(9000)
      expect(potatoes.tax_category_id).to eq(tax_category2.id)
      expect(potatoes.shipping_category_id).to eq(shipping_category.id)
      expect(potatoes.available_on).to be_within(1.day).of(Time.zone.local(2020, 1, 1))
    end
  end
end
