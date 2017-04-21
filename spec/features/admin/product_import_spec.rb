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

    it "validates entries and saves them if they are all valid and allows viewing new items in Bulk Products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_selector 'button.start_import'
      expect(page).to have_selector "button.review[disabled='disabled']"

      click_button 'Import'
      wait_until { page.find("button.review:not([disabled='disabled'])").present? }
      click_button 'Review'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "2"
      expect(page).to_not have_selector '.update-count'

      click_link 'Proceed'

      expect(page).to have_selector 'button.start_save'
      expect(page).to have_selector "button.view_results[disabled='disabled']"

      sleep 0.5
      click_button 'Save'
      wait_until { page.find("button.view_results:not([disabled='disabled'])").present? }

      click_button 'Results'

      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to_not have_selector '.updated-count'

      carrots = Spree::Product.find_by_name('Carrots')
      potatoes = Spree::Product.find_by_name('Potatoes')
      potatoes.supplier.should == enterprise
      potatoes.on_hand.should == 6
      potatoes.price.should == 6.50
      potatoes.variants.first.import_date.should be_within(1.minute).of DateTime.now

      wait_until { page.find("a.button.view").present? }

      click_link 'View Products'

      expect(page).to have_content 'Bulk Edit Products'
      wait_until { page.find("#p_#{potatoes.id}").present? }
      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
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
      click_button 'Upload'

      click_button 'Import'
      wait_until { page.find("button.review:not([disabled='disabled'])").present? }
      click_button 'Review'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "2"
      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'

      expect(page).to_not have_selector 'input[type=submit][value="Save"]'
    end

    it "records a timestamp on import that can be viewed and filtered under Bulk Edit Products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      click_button 'Import'
      wait_until { page.find("button.review:not([disabled='disabled'])").present? }
      click_button 'Review'

      click_link 'Proceed'
      sleep 0.5
      click_button 'Save'
      wait_until { page.find("button.view_results:not([disabled='disabled'])").present? }
      click_button 'Results'

      carrots = Spree::Product.find_by_name('Carrots')
      carrots.variants.first.import_date.should be_within(1.minute).of DateTime.now
      potatoes = Spree::Product.find_by_name('Potatoes')
      potatoes.variants.first.import_date.should be_within(1.minute).of DateTime.now

      click_link 'View Products'

      wait_until { page.find("#p_#{carrots.id}").present? }

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
      find("div#columns-dropdown", :text => "COLUMNS").click
      find("div#columns-dropdown div.menu div.menu_item", text: "Import").click
      find("div#columns-dropdown", :text => "COLUMNS").click

      within "tr#p_#{carrots.id} td.import_date" do
        expect(page).to have_content DateTime.now.year
      end

      expect(page).to have_selector 'div#s2id_import_date_filter'
      import_time = carrots.import_date.to_date.to_formatted_s(:long)
      select import_time, from: "import_date_filter", visible: false

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
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
      click_button 'Upload'

      click_button 'Import'
      wait_until { page.find("button.review:not([disabled='disabled'])").present? }
      click_button 'Review'

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'
      expect(page).to have_selector '.inv-create-count', text: "2"
      expect(page).to have_selector '.inv-update-count', text: "1"

      click_link 'Proceed'
      sleep 0.5
      click_button 'Save'
      wait_until { page.find("button.view_results:not([disabled='disabled'])").present? }
      click_button 'Results'

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

      click_link 'View Inventory'
      expect(page).to have_content 'Inventory'

      select enterprise2.name, from: "hub_id", visible: false

      within '#variant-overrides' do
        expect(page).to have_content 'Beans'
        expect(page).to have_content 'Sprouts'
        expect(page).to have_content 'Cabbage'
      end
    end
  end

  describe "when dealing with uploaded files" do
    before { quick_login_as_admin }

    it "checks filetype on upload" do
      File.write('/tmp/test.txt', "Wrong filetype!")

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.txt'
      click_button 'Upload'

      expect(page).to have_content "Importer could not process file: invalid filetype"
      expect(page).to_not have_selector 'input[type=submit][value="Save"]'
      expect(page).to have_content "Select a spreadsheet to upload"
      File.delete('/tmp/test.txt')
    end

    it "returns an error if nothing was uploaded" do
      visit main_app.admin_product_import_path
      click_button 'Upload'

      expect(flash_message).to eq I18n.t(:product_import_file_not_found_notice)
    end

    it "handles cases where no meaningful data can be read from the file" do
      File.write('/tmp/test.csv', "A22££S\\\\\n**VA,,,AF..D")

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

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
      click_button 'Upload'

      click_button 'Import'
      wait_until { page.find("button.review:not([disabled='disabled'])").present? }
      click_button 'Review'

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"

      expect(page.body).to have_content 'you do not have permission'

      click_link 'Proceed'
      sleep 0.5
      click_button 'Save'
      wait_until { page.find("button.view_results:not([disabled='disabled'])").present? }
      click_button 'Results'

      expect(page).to have_selector '.created-count', text: '1'

      Spree::Product.find_by_name('My Carrots').should be_a Spree::Product
      Spree::Product.find_by_name('Your Potatoes').should == nil
    end
  end
end
