# frozen_string_literal: false

require 'system_helper'
require 'open_food_network/permissions'

describe "Product Import" do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let!(:admin) { create(:admin_user) }
  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:enterprise) { create(:supplier_enterprise, owner: user, name: "User Enterprise") }
  let!(:enterprise2) { create(:distributor_enterprise, owner: user2, name: "Another Enterprise") }
  let!(:relationship) {
    create(:enterprise_relationship, parent: enterprise, child: enterprise2,
                                     permissions_list: [:create_variant_overrides])
  }

  let!(:category) { create(:taxon, name: 'Vegetables') }
  let!(:category2) { create(:taxon, name: 'Cake') }
  let!(:tax_category) { create(:tax_category) }
  let!(:tax_category2) { create(:tax_category) }
  let!(:shipping_category) { create(:shipping_category) }

  let!(:product) { create(:simple_product, supplier: enterprise2, name: 'Hypothetical Cake') }
  let!(:variant) {
    create(:variant, product_id: product.id, price: '8.50', on_hand: 100, unit_value: '500',
                     display_name: 'Preexisting Banana')
  }
  let!(:product2) {
    create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Beans', unit_value: '500',
                            description: '', primary_taxon_id: category.id)
  }
  let!(:product3) {
    create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Sprouts', unit_value: '500')
  }
  let!(:product4) {
    create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Cabbage', unit_value: '500')
  }
  let!(:product5) {
    create(:simple_product, supplier: enterprise2, on_hand: 100, name: 'Lettuce', unit_value: '500')
  }
  let!(:variant_override) {
    create(:variant_override, variant_id: product4.variants.first.id, hub: enterprise2,
                              count_on_hand: 42)
  }
  let!(:variant_override2) {
    create(:variant_override, variant_id: product5.variants.first.id, hub: enterprise,
                              count_on_hand: 96)
  }

  let(:shipping_category_id_str) { Spree::ShippingCategory.all.first.id.to_s }

  describe "when importing products from uploaded file" do
    before do
      allow(Spree::Config).to receive(:available_units).and_return("g,lb,oz,kg,T,mL,L,kL")
      login_as_admin
    end
    after { File.delete('/tmp/test.csv') }

    it "validates entries and saves them if they are all valid and allows viewing new items " \
       "in Bulk Products" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, units, unit_type, shipping_category_id
        Carrots, User Enterprise, Vegetables, 5, 3.20, 500, g, #{shipping_category_id_str}
        Potatoes, User Enterprise, Vegetables, 6, 6.50, 1, kg, #{shipping_category_id_str}
      CSV
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
      expect(potatoes.variants.first.price).to eq 6.50
      expect(potatoes.variants.first.import_date).to be_within(1.minute).of Time.zone.now

      wait_until { page.find("a.button.view").present? }

      click_link 'Go To Products Page'

      expect(page).to have_content 'Bulk Edit Products'
      wait_until { page.find("#p_#{potatoes.id}").present? }
      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
    end

    it "displays info about invalid entries but no save button if all items are invalid" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, units, unit_type, shipping_category_id
        Carrots, User Enterprise, Vegetables, 5, 3.20, 500, g, #{shipping_category_id_str}
        Carrots, User Enterprise, Vegetables, 5, 5.50, 1, kg, #{shipping_category_id_str}
        Bad Carrots, Unkown Enterprise, Mouldy vegetables, 666, 3.20, , g, \
          #{shipping_category_id_str}
        Bad Potatoes, , Vegetables, 6, 6, 6, ,
      CSV
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

    it "displays info about inconsistent variant unit names, within the same product" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, units, unit_type, variant_unit_name, \
          shipping_category_id
        Carrots, User Enterprise, Vegetables, 50, 3.20, 250, , Bag, #{shipping_category_id_str}
        Carrots, User Enterprise, Vegetables, 50, 6.40, 500, , Big-Bag, #{shipping_category_id_str}
      CSV
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation
      find('div.header-description', text: 'Items contain errors').click
      expect(page).to have_content "Variant_unit_name must be the same for products " \
                                   "with the same name"
      expect(page).to have_content "Imported file contains invalid entries"

      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
    end

    it "handles saving of named tax and shipping categories" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, units, unit_type, tax_category, shipping_category
        Carrots, User Enterprise, Vegetables, 5, 3.20, 500, g, #{tax_category.name}, \
          #{shipping_category.name}
      CSV
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
      expect(carrots.variants.first.tax_category).to eq tax_category
      expect(carrots.shipping_category).to eq shipping_category
    end

    it "records a timestamp on import that can be viewed and filtered under Bulk Edit Products" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, units, unit_type, shipping_category_id
        Carrots, User Enterprise, Vegetables, 5, 3.20, 500, g, #{shipping_category_id_str}
        Potatoes, User Enterprise, Vegetables, 6, 6.50, 1, kg, #{shipping_category_id_str}
      CSV
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

      click_link 'Go To Products Page'

      wait_until { page.find("#p_#{carrots.id}").present? }

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
      toggle_columns "Import"

      within "tr#p_#{carrots.id} td.import_date" do
        expect(page).to have_content Time.zone.now.year
      end

      expect(page).to have_selector 'div#s2id_import_date_filter'
      import_time = carrots.import_date.to_date.to_fs(:long).gsub('  ', ' ')
      select2_select import_time, from: "import_date_filter"
      page.find('.button.icon-search').click

      expect(page).to have_field "product_name", with: carrots.name
      expect(page).to have_field "product_name", with: potatoes.name
      expect(page).to have_no_field "product_name", with: product.name
      expect(page).to have_no_field "product_name", with: product2.name
    end

    it "can reset product stock to zero for products not present in the CSV" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, units, unit_type, shipping_category_id
        Carrots, User Enterprise, Vegetables, 500, 3.20, 500, g, #{shipping_category_id_str}
      CSV
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

    it "can save a new product and variant of that product at the same time, " \
       "add variant to existing product" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, units, unit_type, display_name, \
          shipping_category_id
        Potatoes, User Enterprise, Vegetables, 5, 3.50, 500, g, Small Bag, \
          #{shipping_category_id_str}
        Potatoes, User Enterprise, Vegetables, 6, 5.50, 2000, g, Big Bag, \
          #{shipping_category_id_str}
        Beans, User Enterprise, Vegetables, 7, 2.50, 250, g, , #{shipping_category_id_str}
      CSV
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
      csv_data = <<~CSV
        name, distributor, producer, category, on_hand, price, units
        Beans, Another Enterprise, User Enterprise, Vegetables, 5, 3.20, 500
        Sprouts, Another Enterprise, User Enterprise, Vegetables, 6, 6.50, 500
        Cabbage, Another Enterprise, User Enterprise, Vegetables, 2001, 1.50, 500
      CSV
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      select 'Inventories', from: "settings_import_into"
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

      beans_override = VariantOverride.where(variant_id: product2.variants.first.id,
                                             hub_id: enterprise2.id).first
      sprouts_override = VariantOverride.where(variant_id: product3.variants.first.id,
                                               hub_id: enterprise2.id).first
      cabbage_override = VariantOverride.where(variant_id: product4.variants.first.id,
                                               hub_id: enterprise2.id).first

      expect(Float(beans_override.price)).to eq 3.20
      expect(beans_override.count_on_hand).to eq 5

      expect(Float(sprouts_override.price)).to eq 6.50
      expect(sprouts_override.count_on_hand).to eq 6

      expect(Float(cabbage_override.price)).to eq 1.50
      expect(cabbage_override.count_on_hand).to eq 2001

      click_link 'Go To Inventory Page'
      expect(page).to have_content 'Inventory'

      select enterprise2.name, from: "hub_id", visible: false

      within '#variant-overrides' do
        expect(page).to have_content 'Beans'
        expect(page).to have_content 'Sprouts'
        expect(page).to have_content 'Cabbage'
      end
    end

    it "handles a unit of kg for inventory import" do
      product = create(:simple_product, supplier: enterprise, on_hand: 100, name: 'Beets',
                                        unit_value: '1000', variant_unit_scale: 1000)
      csv_data = <<~CSV
        name, distributor, producer, category, on_hand, price, unit_type, units, on_demand
        Beets, Another Enterprise, User Enterprise, Vegetables, , 3.20, kg, 1, 1
      CSV
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      select 'Inventories', from: "settings_import_into"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "1"
      expect(page).to have_no_selector '.invalid-count'
      expect(page).to have_selector '.inv-create-count', text: '1'

      save_data

      expect(page).to have_selector '.inv-created-count', text: '1'

      visit main_app.admin_inventory_path

      expect(page).to have_content "Beets"
      expect(page).to have_select(
        "variant-overrides-#{Spree::Product.find_by(name: 'Beets').variants.first.id}-on_demand",
        selected: "Yes"
      )
      expect(page).to have_input(
        "variant-overrides-#{Spree::Product.find_by(name: 'Beets').variants.first.id}-price",
        with: "3.2"
      )
    end

    describe "Item type products" do
      let!(:product) {
        create(:simple_product, supplier: enterprise, on_hand: nil, name: 'Aubergine',
                                unit_value: '1', variant_unit_scale: nil, variant_unit: "items",
                                variant_unit_name: "Bag")
      }
      it "are sucessfully imported to inventory" do
        csv_data = <<~CSV
          name, distributor, producer, category, on_hand, price, unit_type, units, on_demand, \
            variant_unit_name
          Aubergine, Another Enterprise, User Enterprise, Vegetables, , 3.3, kg, 1, 1, Bag
        CSV

        File.write('/tmp/test.csv', csv_data)
        visit main_app.admin_product_import_path
        select 'Inventories', from: "settings_import_into"
        attach_file 'file', '/tmp/test.csv'
        click_button 'Upload'
        proceed_to_validation
        expect(page).to have_selector '.item-count', text: "1"
        expect(page).to have_no_selector '.invalid-count'
        expect(page).to have_selector '.inv-create-count', text: '1'
        save_data

        expect(page).to have_selector '.inv-created-count', text: '1'

        visit main_app.admin_inventory_path

        expect(page).to have_content "Aubergine"
        expect(page).to have_select(
          "variant-overrides-#{Spree::Product.find_by(name: 'Aubergine').variants.first.id}" \
          "-on_demand", selected: "Yes"
        )
        expect(page).to have_input(
          "variant-overrides-#{Spree::Product.find_by(name: 'Aubergine').variants.first.id}" \
          "-price", with: "3.3"
        )
      end

      it "displays the appropriate error message, when variant unit names are inconsistent" do
        csv_data = <<~CSV
          name, distributor, producer, category, on_hand, price, unit_type, units, on_demand, \
            variant_unit_name
          Aubergine, Another Enterprise, User Enterprise, Vegetables, , 3.3, kg, 1, 1, Bag
          Aubergine, Another Enterprise, User Enterprise, Vegetables, , 6.6, kg, 1, 1, Big-Bag
        CSV

        File.write('/tmp/test.csv', csv_data)
        visit main_app.admin_product_import_path
        select 'Inventories', from: "settings_import_into"
        attach_file 'file', '/tmp/test.csv'
        click_button 'Upload'
        proceed_to_validation

        find('div.header-description', text: 'Items contain errors').click
        expect(page).to have_content "Variant_unit_name must be the same for products " \
                                     "with the same name"
        expect(page).to have_content "Imported file contains invalid entries"
        expect(page).to have_no_selector 'input[type=submit][value="Save"]'

        visit main_app.admin_inventory_path

        expect(page).not_to have_content "Aubergine"
      end

      it "invalidates units value if 0 or non-numeric" do
        csv_data = <<~CSV
          name, distributor, producer, category, on_hand, price, unit_type, units, on_demand, \
            variant_unit_name
          Aubergine, Another Enterprise, User Enterprise, Vegetables, , 3.3, kg, 1, 1, Bag
          Beans, Another Enterprise, User Enterprise, Vegetables, 3, 3.0, kg, 0, 1, Bag
          Cabbage, Another Enterprise, User Enterprise, Vegetables, 1, 4.3, kg, XX, , Bag
        CSV

        File.write('/tmp/test.csv', csv_data)
        visit main_app.admin_product_import_path
        select 'Inventories', from: "settings_import_into"
        attach_file 'file', '/tmp/test.csv'
        click_button 'Upload'
        proceed_to_validation
        expect(page).to have_selector '.item-count', text: "3"
        expect(page).to have_selector '.invalid-count', text: "2"
        expect(page).to have_selector '.inv-create-count', text: '1'

        find('div.header-description', text: 'Items contain errors').click
        expect(page).to have_content "line 4: Cabbage - Units incorrect value"
        expect(page).to have_content "line 3: Beans - Units incorrect value"
        expect(page).to have_content "Imported file contains invalid entries"
        expect(page).to have_no_selector 'input[type=submit][value="Save"]'
        expect(page).not_to have_content "line 2: Aubergine"
      end

      it "Price validation" do
        csv_data = <<~CSV
          name, distributor, producer, category, on_hand, price, unit_type, units, on_demand, \
            variant_unit_name
          Aubergine, Another Enterprise, User Enterprise, Vegetables, , 3.3, kg, 1, 1, Bag
          Beans, Another Enterprise, User Enterprise, Vegetables, 3, , kg, 2, 1, Bag
          Cabbage, Another Enterprise, User Enterprise, Vegetables, 1, t6, kg, 3, , Bag
        CSV

        File.write('/tmp/test.csv', csv_data)
        visit main_app.admin_product_import_path
        select 'Inventories', from: "settings_import_into"
        attach_file 'file', '/tmp/test.csv'
        click_button 'Upload'
        proceed_to_validation
        expect(page).to have_selector '.item-count', text: "3"
        expect(page).to have_selector '.invalid-count', text: "2"
        expect(page).to have_selector '.inv-create-count', text: '1'

        find('div.header-description', text: 'Items contain errors').click
        expect(page).to have_content "line 4: Cabbage - Price incorrect value"
        expect(page).to have_content "line 3: Beans - Price can't be blank"
        expect(page).to have_content "Imported file contains invalid entries"
        expect(page).to have_no_selector 'input[type=submit][value="Save"]'
        expect(page).not_to have_content "line 2: Aubergine"
      end
    end

    it "handles on_demand and on_hand validations with inventory - nill or empty values" do
      csv_data = <<~CSV
        name, distributor, producer, category, on_hand, price, units, on_demand
        Beans, Another Enterprise, User Enterprise, Vegetables, , 3.20, 500, 1
        Sprouts, Another Enterprise, User Enterprise, Vegetables, 6, 6.50, 500, 0
        Cabbage, Another Enterprise, User Enterprise, Vegetables, , 1.50, 500,
        Aubergine, Another Enterprise, User Enterprise, Vegetables, , 1.50, 500,
      CSV
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      select 'Inventories', from: "settings_import_into"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "4"
      expect(page).to have_selector '.inv-create-count', text: '2'
      expect(page).to have_selector '.invalid-count', text: "2"

      find('div.header-description', text: 'Items contain errors').click
      expect(page)
        .to have_content "line 4: Cabbage - On_hand incorrect value - On_demand incorrect value"
      expect(page)
        .to have_content "line 5: Aubergine - On_hand incorrect value - On_demand incorrect value"
      expect(page).to have_content "Imported file contains invalid entries"
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
      expect(page).not_to have_content "line 2: Beans"
      expect(page).not_to have_content "line 3: Sprouts"
    end

    it "handles on_demand and on_hand validations - non-numeric values" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, on_demand, units, unit_type, display_name, \
          shipping_category_id
        Beans, User Enterprise, Vegetables, invalid, 3.50, 1, 0.5, g, Small Bag, \
          #{shipping_category_id_str}
        Potatoes, User Enterprise, Vegetables, 6, 6, invalid, 5, kg, Big Bag, \
          #{shipping_category_id_str}
        Cabbage, User Enterprise, Vegetables, invalid, 1.5, invalid, 1, kg, Bag, \
          #{shipping_category_id_str}
        Aubergine, User Enterprise, Vegetables, , 1.5, invalid, 1, kg, Bag, \
          #{shipping_category_id_str}
      CSV
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "4"
      expect(page).to have_selector '.create-count', text: '2'
      expect(page).to have_selector '.invalid-count', text: "2"

      find('div.header-description', text: 'Items contain errors').click
      expect(page).to have_content "line 4: Cabbage ( Bag ) - On_hand incorrect value - " \
                                   "On_demand incorrect value"
      expect(page).to have_content "line 5: Aubergine ( Bag ) - On_hand incorrect value - " \
                                   "On_demand incorrect value"
      expect(page).to have_content "Imported file contains invalid entries"
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
      expect(page).not_to have_content "line 2: Beans"
      expect(page).not_to have_content "line 3: Potatoes"
    end

    it "handles on_demand and on_hand validations - negative values" do
      csv_data = <<~CSV
        name, producer, category, on_hand, price, on_demand, units, unit_type, display_name, \
          shipping_category_id
        Beans, User Enterprise, Vegetables, -1, 3.50, 1, 500, g, Small Bag, \
          #{shipping_category_id_str}
        Potatoes, User Enterprise, Vegetables, 6, 6, -1, 500, g, Big Bag, \
          #{shipping_category_id_str}
        Cabbage, User Enterprise, Vegetables, -1, 1.5, -1, 1, kg, Bag, #{shipping_category_id_str}
        Aubergine, User Enterprise, Vegetables, , 1.5, -1, 1, kg, Bag, #{shipping_category_id_str}
      CSV
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "4"
      expect(page).to have_selector '.create-count', text: '2'
      expect(page).to have_selector '.invalid-count', text: "2"

      find('div.header-description', text: 'Items contain errors').click
      expect(page).to have_content "line 4: Cabbage ( Bag ) - On_hand incorrect value - " \
                                   "On_demand incorrect value"
      expect(page).to have_content "line 5: Aubergine ( Bag ) - On_hand incorrect value - " \
                                   "On_demand incorrect value"
      expect(page).to have_content "Imported file contains invalid entries"
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
      expect(page).not_to have_content "line 2: Beans"
      expect(page).not_to have_content "line 3: Sprouts"
    end

    it "handles on_demand and on_hand validations with inventory - With both values set" do
      csv_data = <<~CSV
        name, distributor, producer, category, on_hand, price, units, on_demand
        Beans, Another Enterprise, User Enterprise, Vegetables, 6, 3.20, 500, 1
        Sprouts, Another Enterprise, User Enterprise, Vegetables, 6, 6.50, 500, 1
        Cabbage, Another Enterprise, User Enterprise, Vegetables, 0, 1.50, 500, 1
      CSV
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      select 'Inventories', from: "settings_import_into"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "3"
      expect(page).to have_selector '.invalid-count', text: "3"

      find('div.header-description', text: 'Items contain errors').click
      expect(page).to have_content "line 2: Beans - Count_on_hand must be blank if on demand"
      expect(page).to have_content "line 3: Sprouts - Count_on_hand must be blank if on demand"
      expect(page).to have_content "line 4: Cabbage - Count_on_hand must be blank if on demand"
      expect(page).to have_content "Imported file contains invalid entries"
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
    end

    it "imports lines with all allowed units" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type",
                "shipping_category_id"]
        csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "1", "lb",
                shipping_category_id_str]
        csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "8", "oz",
                shipping_category_id_str]
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

      visit spree.admin_products_path

      within "#p_#{Spree::Product.find_by(name: 'Carrots').id}" do
        expect(page).to have_input "product_name", with: "Carrots"
        expect(page).to have_select "variant_unit_with_scale", selected: "Weight (lb)"
        expect(page).to have_content "5" # on_hand
      end
    end

    it "imports lines with item products" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type",
                "variant_unit_name", "shipping_category_id"]
        csv << ["Cupcake", "User Enterprise", "Cake", "5", "2.2", "1", "", "Bunch",
                shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path

      expect(page).to have_content "Select a spreadsheet to upload"
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_selector '.item-count', text: "1"
      expect(page).to have_no_selector '.invalid-count'
      expect(page).to have_selector '.create-count', text: "1"
      expect(page).to have_no_selector '.update-count'

      save_data

      expect(page).to have_selector '.created-count', text: '1'
      expect(page).to have_no_selector '.updated-count'
      expect(page).to have_content "GO TO PRODUCTS PAGE"
      expect(page).to have_content "UPLOAD ANOTHER FILE"

      visit spree.admin_products_path

      within "#p_#{Spree::Product.find_by(name: 'Cupcake').id}" do
        expect(page).to have_input "product_name", with: "Cupcake"
        expect(page).to have_select "variant_unit_with_scale", selected: "Items"
        expect(page).to have_input "variant_unit_name", with: "Bunch"
        expect(page).to have_content "5" # on_hand
      end
    end

    it "does not allow import for lines with unknown units" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type",
                "shipping_category_id"]
        csv << ["Heavy Carrots", "Unkown Enterprise", "Mouldy vegetables", "666", "3.20", "1",
                "stones", shipping_category_id_str]
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

    context 'when using other language than English' do
      around do |example|
        original_default_locale = I18n.default_locale
        # Set the language to Spanish
        I18n.default_locale = 'es'
        example.run
        I18n.default_locale = original_default_locale
      end

      xit 'returns the header in selected language' do
        csv_data = CSV.generate do |csv|
          csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type",
                  "shipping_category"]
          csv << ["Carrots", "User Enterprise", "Vegetables", "5", "3.20", "1", "lb",
                  shipping_category_id_str]
          csv << ["Potatoes", "User Enterprise", "Vegetables", "6", "6.50", "8", "oz",
                  shipping_category_id_str]
        end
        File.write('/tmp/test.csv', csv_data)

        visit main_app.admin_product_import_path

        expect(page).to have_content 'Importación de productos'
        expect(page).to have_content 'Selecciona una hoja de cálculo para subir'
        attach_file 'file', '/tmp/test.csv'
        click_button 'Subir'
        find('a.button.proceed').click

        within('.panel-header .header-caret') { find('i').click }

        within('.panel-content .table-wrap') do
          product_headings = ['producer', 'category', 'units', 'unit_type',
                              'price', 'on_hand', 'shipping_category', 'name']

          product_headings.each do |heading|
            expect(page).to have_content(
              I18n.t("admin.product_import.product_headings.#{heading}").upcase
            )
          end
        end
      end
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

      expect(flash_message).to eq 'File not found or could not be opened'
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
      csv_data += "Malformed \rBrocolli,#{enterprise.name},Vegetables,8,2.50,200,g," \
                  "#{shipping_category.name}\n"

      File.write('/tmp/test.csv', csv_data)

      visit main_app.admin_product_import_path
      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      expect(page).to have_no_selector '.create-count'
      expect(page).to have_no_selector '.update-count'
      expect(page).to have_no_selector 'input[type=submit][value="Save"]'
      expect(flash_message).to match("Product Import encountered a malformed CSV: %s" % '')

      File.delete('/tmp/test.csv')
    end
  end

  describe "handling enterprise permissions" do
    after { File.delete('/tmp/test.csv') }

    it "only allows product import into enterprises the user is permitted to manage" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "producer", "category", "on_hand", "price", "units", "unit_type",
                "shipping_category_id"]
        csv << ["My Carrots", "User Enterprise", "Vegetables", "5", "3.20", "500", "g",
                shipping_category_id_str]
        csv << ["Your Potatoes", "Another Enterprise", "Vegetables", "6", "6.50", "1", "kg",
                shipping_category_id_str]
      end
      File.write('/tmp/test.csv', csv_data)

      login_as user
      visit main_app.admin_product_import_path

      attach_file 'file', '/tmp/test.csv'
      click_button 'Upload'

      proceed_to_validation

      expect(page).to have_content 'Import validation overview'
      expect(page).to have_selector '.item-count', text: "2"
      expect(page).to have_selector '.invalid-count', text: "1"
      expect(page).to have_selector '.create-count', text: "1"

      expect(page.body).to have_content 'you do not have permission'
      expect(page).to have_no_selector 'a.button.proceed'
    end
  end

  describe "handling a large file (120 data rows)" do
    let!(:producer) { enterprise }
    let!(:tax_category) { create(:tax_category, name: "Tax Category Name") }
    let!(:shipping_category) { create(:shipping_category, name: "Shipping Category Name") }

    let!(:csv_file) { Rails.root.join('spec/fixtures/files/sample_file_120_products.csv') }

    before do
      login_as admin
      visit main_app.admin_product_import_path
    end

    context "when importing to product list" do
      it "validates and saves all batches" do
        # Upload and validate file.
        attach_file "file", csv_file
        click_button 'Upload'
        proceed_to_validation

        # Check that all rows are validated.
        heading = 'Products will be created'
        find(".header-description", text: heading).click
        expect(page).to have_content "Imported Product 10"
        expect(page).to have_content "Imported Product 60"
        expect(page).to have_content "Imported Product 110"

        # Save file.
        proceed_with_save

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
    expect(page).to have_selector 'a.button.proceed'
    within("#content") { click_link 'Import' }
    expect(page).to have_selector 'form.product-import'
    expect(page).to have_content 'Import validation overview'
  end

  def save_data
    expect(page).to have_selector 'a.button.proceed'
    proceed_with_save
    expect(page).to have_selector 'div.save-results'
    expect_import_completed
  end

  def proceed_with_save
    click_link 'Save'
  end

  def expect_import_completed
    # The step pages are hidden and shown by AngularJS and we get a false
    # positive when querying for the content of a hidden step.
    #
    #   expect(page).to have_content I18n.t('admin.product_import.save_results.final_results')
    #
    # Being more explicit seems to work:
    using_wait_time 60 do
      expect(page).to have_selector("h5", text: "Import final results")
    end
  end
end
