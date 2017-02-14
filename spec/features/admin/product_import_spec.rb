require 'spec_helper'
require 'open_food_network/permissions'

feature "Product Import", js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:admin) { create(:admin_user) }
  let!(:user) { create_enterprise_user }
  let!(:enterprise) { create(:enterprise, owner: user, name: "Test Enterprise") }
  let!(:category) { create(:taxon, name: 'Vegetables') }
  let(:permissions) { OpenFoodNetwork::Permissions.new(user) }

  describe "product import" do
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
      attach_file('file', '/tmp/test.csv')
      click_button('Import')

      expect(page).to have_content("Valid entries found: 2")
      expect(page).to have_content("Invalid entries found: 0")
      click_button('Save')

      expect(page).to have_content("Products created: 2")

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
      click_button('Import')

      expect(page).to have_content("Valid entries found: 1")
      expect(page).to have_content("Invalid entries found: 1")
      expect(page).to have_content("errors")

      click_button('Save')

      expect(page).to have_content("Products created: 1")

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
      attach_file('file', '/tmp/test.csv')
      click_button('Import')

      expect(page).to have_content("Valid entries found: 0")
      expect(page).to have_content("Invalid entries found: 2")
      expect(page).to have_content("errors")

      expect(page).to_not have_selector('input[type=submit]', text: "Save")
    end
  end

  # Test enterprise permissions with non-admin user
end