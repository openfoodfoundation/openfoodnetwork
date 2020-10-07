require 'spec_helper'
require 'open_food_network/permissions'

feature "Product Import", js: true do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let!(:admin) { create(:admin_user) }
  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:enterprise) { create(:supplier_enterprise, owner: user, name: "User Enterprise") }
  let!(:enterprise2) { create(:distributor_enterprise, owner: user2, name: "Another Enterprise") }
  let!(:relationship) { create(:enterprise_relationship, parent: enterprise, child: enterprise2, permissions_list: [:create_variant_overrides]) }

  let!(:category) { create(:taxon, name: 'Vegetables') }
  let!(:category2) { create(:taxon, name: 'Cake') }
  let!(:tax_category) { create(:tax_category) }
  let!(:tax_category2) { create(:tax_category) }
  let!(:shipping_category) { create(:shipping_category) }

  let!(:product) { create(:simple_product, supplier: enterprise2, name: 'Hypothetical Cake') }
  let!(:variant) { create(:variant, product_id: product.id, price: '8.50', on_hand: 100, unit_value: '500', display_name: 'Preexisting Banana') }
  let!(:product2) { create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Beans', unit_value: '500', description: '', primary_taxon_id: category.id) }
  let!(:product3) { create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Sprouts', unit_value: '500') }
  let!(:product4) { create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Cabbage', unit_value: '500') }
  let!(:product5) { create(:simple_product, supplier: enterprise2, on_hand: 100, name: 'Lettuce', unit_value: '500') }
  let!(:variant_override) { create(:variant_override, variant_id: product4.variants.first.id, hub: enterprise2, count_on_hand: 42) }
  let!(:variant_override2) { create(:variant_override, variant_id: product5.variants.first.id, hub: enterprise, count_on_hand: 96) }

  let(:shipping_category_id_str) { Spree::ShippingCategory.all.first.id.to_s }

  describe "when importing products from uploaded file" do
    before { login_as_admin }
    after { File.delete('/tmp/test.csv') }

    it "validates entries and saves them if they are all valid and allows viewing new items in Bulk Products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "shipping_category_id"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", shipping_category_id_str]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1", "kg", shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_no_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "2"
      expect(page).to have_no_selector '.update-count'

      save_data

      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to have_no_selector '.updated-count'

      carrots = Spree::Product.find_by(name: 'Carrots')
      potatoes = Spree::Product.find_by(name: 'Potatoes')
      expect(potatoes.supplier).to eq enterprise
      expect(potatoes.on_hand).to eq 6
      expect(potatoes.price).to eq 6.50
      expect(potatoes.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      wait_until { page.find("a.button.view").present? }

      click_link I18n.t('admin.product_import.save_results.view_products')

      expect(page).to have_content 'Bulk Edit Products'
      wait_until { page.find("#p_#{potatoes.id}").present? }
      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
    end

    it "displays info about invalid entries but no save button if all items are invalid" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "shipping_category_id"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", shipping_category_id_str]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "5.50", "1", "kg", shipping_category_id_str]
        csv << ["Bad Carrots", "Unkown Enterprise", "Mouldy vegetables", "666", "3.20", "", "g", shipping_category_id_str]
        csv << ["Bad Potatoes", "", "Vegetables", "6", "6", "6", ""]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "4"
      expect(page).to have_selector '.invalid-count', text: "3"
      expect(page).to have_selector ".create-count", text: "1"
      expect(page).to have_no_selector '.update-count'

      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
    end

    it "handles saving of named tax and shipping categories" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "tax_category", "shipping_category"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", tax_category.name, shipping_category.name]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"
      expect(page).to have_no_selector '.update-count'

      save_data

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_no_selector '.updated-count'

      carrots = Spree::Product.find_by(name: 'Carrots')
      expect(carrots.tax_category).to eq tax_category
      expect(carrots.shipping_category).to eq shipping_category
    end

    it "records a timestamp on import that can be viewed and filtered under Bulk Edit Products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "shipping_category_id"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", shipping_category_id_str]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "1", "kg", shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      save_data

      carrots = Spree::Product.find_by(name: 'Carrots')
      expect(carrots.variants.first.import_date).to be_within(1.minute).of Time.zone.now
      potatoes = Spree::Product.find_by(name: 'Potatoes')
      expect(potatoes.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      click_link I18n.t('admin.product_import.save_results.view_products')

      wait_until { page.find("#p_#{carrots.id}").present? }

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
      toggle_columns "Import"

      within "tr#p_#{carrots.id} td.import_date" do
        expect(page).to have_content Time.zone.now.year
      end

      expect(page).to have_selector 'div#s2id_import_date_filter'
      import_time = carrots.import_date.to_date.to_formatted_s(:long)
      select2_select import_time, from: "import_date_filter"
      page.find('.button.icon-search').click

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
      expect(page).to have_no_field "product_name", with: product.name
      expect(page).to have_no_field "product_name", with: product2.name
    end

    it "can reset product stock to zero for products not present in the CSV" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "shipping_category_id"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "500", "3.20", "500", "g", shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'

      check "settings_reset_all_absent"

      click_button 'Upload'

      proceed_to_validation

      save_data

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_selector '.reset-count', text: '3'

      expect(Spree::Product.find_by(name: 'Carrots').on_hand).to eq 500
      expect(Spree::Product.find_by(name: 'Cabbage').on_hand).to eq 0
      expect(Spree::Product.find_by(name: 'Beans').on_hand).to eq 0
    end

    it "can save a new product and variant of that product at the same time, add variant to existing product" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "display_name", "shipping_category_id"]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "5", "3.50", "500", "g", "Small Bag", shipping_category_id_str]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "5.50", "2000", "g", "Big Bag", shipping_category_id_str]
        csv << ["Beans", "User Enterprise", "Vegetables", "7", "2.50", "250", "g", nil, shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to_not have_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "3"
      expect(page).to_not have_selector '.update-count'
      expect(page).to_not have_selector '.inv-create-count'
      expect(page).to_not have_selector '.inv-update-count'

      save_data

      small_bag = Spree::Variant.find_by(display_name: 'Small Bag')
      expect(small_bag.product.name).to eq 'Potatoes'
      expect(small_bag.price).to eq 3.50
      expect(small_bag.on_hand).to eq 5

      big_bag = Spree::Variant.find_by(display_name: 'Big Bag')
      expect(big_bag.product.name).to eq 'Potatoes'
      expect(big_bag.price).to eq 5.50
      expect(big_bag.on_hand).to eq 6

      expect(big_bag.product.id).to eq small_bag.product.id
    end

    it "can import items into inventory" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "distributor", "producer", "category", "on_hand", "price", "units"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", "5", "3.20", "500"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "6", "6.50", "500"]
        csv << ["Cabbage", "Another Enterprise", "User Enterprise", "Vegetables", "2001", "1.50", "500"]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      select2_select I18n.t('admin.product_import.index.inventories'), from: "settings_import_into"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to have_no_selector '.invalid-count'
      expect(page).to have_no_selector '.create-count'
      expect(page).to have_no_selector '.update-count'
      expect(page).to have_selector '.inv-create-count', text: "2"
      expect(page).to have_selector '.inv-update-count', text: "1"

      save_data

      expect(page).to have_no_selector '.created-count'
      expect(page).to have_no_selector '.updated-count'
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

      click_link I18n.t('admin.product_import.save_results.view_inventory')
      expect(page).to have_content 'Inventory'

      select enterprise2.name, from: "hub_id", visible: false

      within '#variant-overrides' do
        expect(page).to have_content 'Beans'
        expect(page).to have_content 'Sprouts'
        expect(page).to have_content 'Cabbage'
      end
    end

    it "handles a unit of kg for inventory import" do
      product = create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Beets', unit_value: '1000', variant_unit_scale: 1000)
      csv_data = CSV.generate do |csv|
        csv << ["name", "distributor", "producer", "category", "on_hand", "price", "unit_type", "units", "on_demand"]
        csv << ["Beets", "Another Enterprise", "User Enterprise", "Vegetables", nil, "3.20", "kg", "1", "true"]
      end

      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      select2_select I18n.t('admin.product_import.index.inventories'), from: "settings_import_into"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "1"
      expect(page).to have_no_selector '.invalid-count'
      expect(page).to have_selector '.inv-create-count', text: '1'

      save_data

      expect(page).to have_selector '.inv-created-count', text: '1'
    end

    it "handles on_demand and on_hand validations with inventory" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "distributor", "producer", "category", "on_hand", "price", "units", "on_demand"]
        csv << ["Beans", "Another Enterprise", "User Enterprise", "Vegetables", nil, "3.20", "500", "true"]
        csv << ["Sprouts", "Another Enterprise", "User Enterprise", "Vegetables", "6", "6.50", "500", "false"]
        csv << ["Cabbage", "Another Enterprise", "User Enterprise", "Vegetables", nil, "1.50", "500", nil]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      select2_select I18n.t('admin.product_import.index.inventories'), from: "settings_import_into"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to have_no_selector '.invalid-count'
      expect(page).to have_selector '.inv-create-count', text: '2'
      expect(page).to have_selector '.inv-update-count', text: '1'

      save_data

      expect(page).to have_selector '.inv-created-count', text: '2'
      expect(page).to have_selector '.inv-updated-count', text: '1'

      beans_override = VariantOverride.where(variant_id: product2.variants.first.id, hub_id: enterprise2.id).first
      sprouts_override = VariantOverride.where(variant_id: product3.variants.first.id, hub_id: enterprise2.id).first
      cabbage_override = VariantOverride.where(variant_id: product4.variants.first.id, hub_id: enterprise2.id).first

      expect(Float(beans_override.price)).to eq 3.20
      expect(beans_override.count_on_hand).to be_nil
      expect(beans_override.on_demand).to be_truthy

      expect(Float(sprouts_override.price)).to eq 6.50
      expect(sprouts_override.count_on_hand).to eq 6
      expect(sprouts_override.on_demand).to eq false

      expect(Float(cabbage_override.price)).to eq 1.50
      expect(cabbage_override.count_on_hand).to be_nil
      expect(cabbage_override.on_demand).to be_nil
    end

    it "imports lines with all allowed units" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "shipping_category_id"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "1", "lb", shipping_category_id_str]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "8", "oz", shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_no_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "2"
      expect(page).to have_no_selector '.update-count'

      save_data

      expect(page).to have_selector '.created-count', text: '2'
      expect(page).to have_no_selector '.updated-count'
    end

    it "does not allow import for lines with unknown units" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "shipping_category_id"]
        csv << ["Heavy Carrots", "Unkown Enterprise", "Mouldy vegetables", "666", "3.20", "1", "stones", shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "1"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_no_selector ".create-count"
      expect(page).to have_no_selector '.update-count'

      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
    end
  end

  describe "when dealing with uploaded files" do
    before { login_as_admin }

    it "checks filetype on upload" do
      File.write('/tmp/test.txt', "Wrong filetype!")

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.txt'
      click_button 'Upload'

      expect(page).to have_content "Importer could not process file: invalid filetype"
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
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

      expect(page).to have_no_selector '.create-count'
      expect(page).to have_no_selector '.update-count'
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
      File.delete('/tmp/test.csv')
    end

    it "handles cases where files contain malformed data" do
      csv_data = "name,producer,category,on_hand,price,units,unit_type,shipping_category\n"
      csv_data += "Malformed \rBrocolli,#{enterprise.name},Vegetables,8,2.50,200,g,#{shipping_category.name}\n"

      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_no_selector '.create-count'
      expect(page).to have_no_selector '.update-count'
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
      expect(flash_message).to match(I18n.t('admin.product_import.model.malformed_csv', error_message: ""))

      File.delete('/tmp/test.csv')
    end
  end

  describe "handling enterprise permissions" do
    after { File.delete('/tmp/test.csv') }

    it "only allows product import into enterprises the user is permitted to manage" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type", "shipping_category_id"]
        csv << ["My Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g", shipping_category_id_str]
        csv << ["Your Potatoes", "Another Enterprise", "Vegetables", "6", "6.50", "1", "kg", shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      login_as user
      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_content I18n.t('admin.product_import.import.validation_overview')
      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"

      expect(page.body).to have_content 'you do not have permission'
      expect(page).to have_no_selector 'a.button.proceed', visible: true
    end
  end

  describe "handling a large file (120 data rows)" do
    let!(:producer) { enterprise }

    let(:tmp_csv_path) { "/tmp/test.csv" }

    before do
      login_as admin
      visit main_app.admin_product_import_path
    end

    context "when importing to product list" do
      def write_tmp_csv_file
        CSV.open(tmp_csv_path, "w") do |csv|
          csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type",
                  "tax_category", "shipping_category"]
          120.times do |i|
            csv << ["Imported Product #{i + 1}", producer.name, category.name, 1, "1.00", "500",
                    "g", tax_category.name, shipping_category.name]
          end
        end
      end

      before { write_tmp_csv_file }

      it "validates and saves all batches" do
        # Upload and validate file.
        attach_file "file", tmp_csv_path
        click_button I18n.t("admin.product_import.index.upload")
        proceed_to_validation

        # Check that all rows are validated.
        heading = "120 #{I18n.t('admin.product_import.import.products_to_create')}"
        find(".panel-header", text: heading).click
        expect(page).to have_content "Imported Product 10"
        expect(page).to have_content "Imported Product 60"
        expect(page).to have_content "Imported Product 110"

        # Save file.
        proceed_with_save

        # Be extra patient.
        expect_progress_percentages "33%", "67%", "100%"
        expect_import_completed

        # Check that all rows are saved.
        expect(producer.supplied_products.find_by(name: "Imported Product 10")).to be_present
        expect(producer.supplied_products.find_by(name: "Imported Product 60")).to be_present
        expect(producer.supplied_products.find_by(name: "Imported Product 110")).to be_present
      end
    end
  end

  private

  def proceed_to_validation
    expect(page).to have_selector 'a.button.proceed', visible: true
    within("#content") { click_link I18n.t('admin.product_import.import.import') }
    expect(page).to have_selector 'form.product-import', visible: true
    expect(page).to have_content I18n.t('admin.product_import.import.validation_overview')
  end

  def save_data
    expect(page).to have_selector 'a.button.proceed', visible: true
    proceed_with_save
    expect(page).to have_selector 'div.save-results', visible: true
    expect_import_completed
  end

  def expect_progress_percentages(*percentages)
    percentages.each do |percentage|
      expect(page).to have_selector ".progress-interface", text: percentage
    end
  end

  def proceed_with_save
    click_link I18n.t("admin.product_import.import.save")
  end

  def expect_import_completed
    expect(page).to have_content I18n.t('admin.product_import.save_results.final_results')
  end
end
