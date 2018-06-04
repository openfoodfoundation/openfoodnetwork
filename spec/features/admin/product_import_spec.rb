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
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1", "kg"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      import_data

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "2"
      expect(page).to_not have_selector '.update-count'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      save_data

      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to_not have_selector '.updated-count'

      carrots = Spree::Product.find_by_name('Carrots')
      potatoes = Spree::Product.find_by_name('Potatoes')
      expect(potatoes.supplier).to eq enterprise
      expect(potatoes.on_hand).to eq 6
      expect(potatoes.price).to eq 6.50
      expect(potatoes.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      wait_until { page.find("a.button.view").present? }

      click_link 'View Products'

      expect(page).to have_content 'Bulk Edit Products'
      wait_until { page.find("#p_#{potatoes.id}").present? }
      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
    end

    it "displays info about invalid entries but no save button if all items are invalid" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["Bad Carrots", "Unkown Enterprise", "Mouldy vegetables", "666", "3.20", "", "g"]
        csv << ["Bad Potatoes", "", "Vegetables", "6", "6", "6", ""]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      import_data

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "2"
      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'

      expect(page).to_not have_selector 'input[type=submit][value="Save"]'
    end

    it "handles validation and saving of named tax and shipping categories" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type", "tax_category", "shipping_category"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", tax_category.name, shipping_category.name]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1", "kg", "Unknown Tax Category", shipping_category.name]
        csv << ["Peas", "User Enterprise", "Vegetables", "7", "2.50", "1", "kg", tax_category2.name, "Unknown Shipping Category"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      import_data

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to have_selector '.invalid-count', text: "2"
      expect(page).to have_selector '.create-count', text: "1"
      expect(page).to_not have_selector '.update-count'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      save_data

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to_not have_selector '.updated-count'

      carrots = Spree::Product.find_by_name('Carrots')
      expect(carrots.tax_category).to eq tax_category
      expect(carrots.shipping_category).to eq shipping_category
    end

    it "records a timestamp on import that can be viewed and filtered under Bulk Edit Products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1", "kg"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      import_data

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      save_data

      carrots = Spree::Product.find_by_name('Carrots')
      expect(carrots.variants.first.import_date).to be_within(1.minute).of Time.zone.now
      potatoes = Spree::Product.find_by_name('Potatoes')
      expect(potatoes.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      click_link 'View Products'

      wait_until { page.find("#p_#{carrots.id}").present? }

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
      find("div#columns-dropdown", text: "COLUMNS").click
      find("div#columns-dropdown div.menu div.menu_item", text: "Import").click
      find("div#columns-dropdown", text: "COLUMNS").click

      within "tr#p_#{carrots.id} td.import_date" do
        expect(page).to have_content Time.zone.now.year
      end

      expect(page).to have_selector 'div#s2id_import_date_filter'
      import_time = carrots.import_date.to_date.to_formatted_s(:long).gsub('  ', ' ')
      select import_time, from: "import_date_filter", visible: false

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
      expect(page).to_not have_field "product_name", with: product.name
      expect(page).to_not have_field "product_name", with: product2.name
    end

    it "can import items into inventory" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "producer", "category", "on_hand", "price", "units"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "6", "6.50", "500"]
        csv << ["Cabbage", "Another Enterprise", "User Enterprise", "Vegetables", "2001", "1.50", "500"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      within 'div.import-settings' do
        find('div.header-description').click  # Import settings tab
        select 'Inventories', from: "settings_#{enterprise2.id.to_s}_import_into", visible: false
      end

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      import_data

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to_not have_selector '.create-count'
      expect(page).to_not have_selector '.update-count'
      expect(page).to have_selector '.inv-create-count', text: "2"
      expect(page).to have_selector '.inv-update-count', text: "1"

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      save_data

      expect(page).to_not have_selector '.created-count'
      expect(page).to_not have_selector '.updated-count'
      expect(page).to have_selector '.inv-created-count', text: '2'
      expect(page).to have_selector '.inv-updated-count', text: '1'

      beans_override = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts_override = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      cabbage_override = VariantOverride.where(variant_id: product4.variants.first.id, hub_id: enterprise2.id).first

      expect(Float(beans_override.price)).to eq 3.20
      expect(beans_override.count_on_hand).to eq 5

      expect(Float(sprouts_override.price)).to eq 6.50
      expect(sprouts_override.count_on_hand).to eq 6

      expect(Float(cabbage_override.price)).to eq 1.50
      expect(cabbage_override.count_on_hand).to eq 2001

      click_link 'View Inventory'
      expect(page).to have_content 'Inventory'

      select enterprise2.name, from: "hub_id", visible: false

      within '#variant-overrides' do
        expect(page).to have_content 'Beans'
        expect(page).to have_content 'Sprouts'
        expect(page).to have_content 'Cabbage'
      end
    end

    it "can override import fields via the import settings tab" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type", "tax_category", "shipping_category"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", tax_category.name, shipping_category.name]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1", "kg", "Unknown Tax Category", shipping_category.name]
        csv << ["Peas", "User Enterprise", "Vegetables", "7", "2.50", "1", "kg", tax_category2.name, "Unknown Shipping Category"]
        csv << ["Pumpkin", "User Enterprise", "Vegetables", "3", "3.50", "1", "kg", tax_category.name, ""]
        csv << ["Spinach", "User Enterprise", "Vegetables", "7", "3.60", "1", "kg", "", shipping_category.name]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      within 'div.import-settings' do
        find('div.panel-header').click

        within 'tr.stock-level.productlist' do
          find('input[type="checkbox"]').click
          select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_on_hand_mode", visible: false
          fill_in "settings_#{enterprise.id}_defaults_on_hand_value", with: 9000
        end

        within 'tr.tax-category' do
          find('input[type="checkbox"]').click
          select 'Overwrite if empty', from: "settings_#{enterprise.id}_defaults_tax_category_id_mode", visible: false
          select tax_category2.name, from: "settings_#{enterprise.id}_defaults_tax_category_id_value", visible: false
        end

        within 'tr.shipping-category' do
          find('input[type="checkbox"]').click
          select 'Overwrite all', from: "settings_#{enterprise.id}_defaults_shipping_category_id_mode", visible: false
          select shipping_category.name, from: "settings_#{enterprise.id}_defaults_shipping_category_id_value", visible: false
        end
      end

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      import_data

      expect(page).to have_selector '.item-count', text: "5"
      expect(page).to have_selector '.invalid-count', text: "2"
      expect(page).to have_selector '.create-count', text: "3"
      expect(page).to_not have_selector '.update-count'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      save_data

      expect(page).to have_selector '.created-count', text: '3'
      expect(page).to_not have_selector '.updated-count'

      carrots = Spree::Product.find_by_name('Carrots')
      expect(carrots.tax_category).to eq tax_category
      expect(carrots.shipping_category).to eq shipping_category
      expect(carrots.count_on_hand).to eq 9000

      pumpkin = Spree::Product.find_by_name('Pumpkin')
      expect(pumpkin.tax_category).to eq tax_category
      expect(pumpkin.shipping_category).to eq shipping_category
      expect(pumpkin.count_on_hand).to eq 9000

      spinach = Spree::Product.find_by_name('Spinach')
      expect(spinach.tax_category).to eq tax_category2
      expect(spinach.shipping_category).to eq shipping_category
      expect(spinach.count_on_hand).to eq 9000
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
      expect(page).to have_content 'Select a spreadsheet to upload'
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
        csv << ["name", "supplier", "category", "on_hand", "price", "units", "unit_type"]
        csv << ["My Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g"]
        csv << ["Your Potatoes", "Another Enterprise", "Vegetables", "6", "6.50", "1", "kg"]
      end
      File.write('/tmp/test.csv', csv_data)

      quick_login_as user
      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      import_data

      expect(page).to have_content I18n.t('admin.product_import.import.validation_overview')
      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"

      expect(page.body).to have_content 'you do not have permission'

      expect(page).to have_selector 'a.button.proceed', visible: true
      click_link 'Proceed'

      save_data

      expect(page).to have_selector '.created-count', text: '1'

      expect(Spree::Product.find_by_name('My Carrots')).to be_a Spree::Product
      expect(Spree::Product.find_by_name('Your Potatoes')).to be_nil
    end
  end

  private

  def import_data
    expect(page).to have_selector 'button.start_import', visible: true
    expect(page).to have_selector "button.review[disabled='disabled']"

    find('button.start_import').trigger 'click'
    wait_until { page.find("button.review:not([disabled='disabled'])").present? }

    find('button.review').trigger 'click'
    expect(page).to have_content I18n.t('admin.product_import.import.validation_overview')
  end

  def save_data
    expect(page).to have_selector 'button.start_save', visible: true
    expect(page).to have_selector "button.view_results[disabled='disabled']"

    find('button.start_save').trigger 'click'
    wait_until { page.find("button.view_results:not([disabled='disabled'])").present? }

    find('button.view_results').trigger 'click'
    expect(page).to have_content I18n.t('admin.product_import.save.final_results')
  end
end
