require 'spec_helper'
require 'open_food_network/permissions'

feature "Product Import", js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:admin) { create(:admin_user) }
  let!(:user) { create_enterprise_user }
  let!(:enterprise) { create(:supplier_enterprise, owner: user, name: "Test Enterprise") }
  let!(:category) { create(:taxon, name: 'Vegetables') }
  let!(:category2) { create(:taxon, name: 'Cake') }
  let!(:product) { create(:simple_product, supplier: enterprise, name: 'Hypothetical Cake') }
  let!(:variant) { create(:variant, product_id: product.id, price: '8.50', count_on_hand: '100', unit_value: '500', display_name: 'Preexisting Banana') }
  let(:permissions) { OpenFoodNetwork::Permissions.new(user) }

  describe "when importing products from uploaded file" do
    before { quick_login_as_admin }
    after { File.delete('/tmp/test.csv') }

    it "validates entries and saves them if they are all valid" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "Test Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Potatoes", "Test Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
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
      expect(page).to have_content "Products created: 2"

      potatoes = Spree::Product.find_by_name('Potatoes')
      potatoes.supplier.should == enterprise
      potatoes.on_hand.should == 6
      potatoes.price.should == 6.50
    end

    it "displays info about invalid entries but still allows saving of valid entries" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Good Carrots", "Test Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
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
      expect(page).to have_content "Products created: 1"

      Spree::Product.find_by_name('Bad Potatoes').should == nil
      carrots = Spree::Product.find_by_name('Good Carrots')
      carrots.supplier.should == enterprise
      carrots.on_hand.should == 5
      carrots.price.should == 3.20
    end

    it "displays info about invalid entries but no save button if all invalid" do
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
        csv << ["Hypothetical Cake", "Test Enterprise", "Cake", "5", "5.50", "500", "weight", "1", "Preexisting Banana"]
        csv << ["Hypothetical Cake", "Test Enterprise", "Cake", "6", "3.50", "500", "weight", "1", "Emergent Coffee"]
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
      expect(page).to have_content "Products created: 1"
      expect(page).to have_content "Products updated: 1"

      added_coffee = Spree::Variant.find_by_display_name('Emergent Coffee')
      added_coffee.product.name.should == 'Hypothetical Cake'
      added_coffee.price.should == 3.50
      added_coffee.on_hand.should == 6

      updated_banana = Spree::Variant.find_by_display_name('Preexisting Banana')
      updated_banana.product.name.should == 'Hypothetical Cake'
      updated_banana.price.should == 5.50
      updated_banana.on_hand.should == 5
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
      click_button 'Import'

      expect(page).to have_content "File not found or could not be opened"
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

  # Test enterprise permissions with non-admin user
end