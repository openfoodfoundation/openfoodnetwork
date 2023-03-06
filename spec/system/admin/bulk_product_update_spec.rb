# frozen_string_literal: true

require 'system_helper'

describe '
  As an Administrator
  I want to be able to manage products in bulk
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  describe "listing products" do
    before do
      login_as_admin
    end

    it "displays a list of products" do
      p1 = FactoryBot.create(:product)
      p2 = FactoryBot.create(:product)

      visit spree.admin_products_path

      expect(page).to have_field "product_name", with: p1.name
      expect(page).to have_field "product_name", with: p2.name
    end

    it "displays a message when number of products is zero" do
      visit spree.admin_products_path

      expect(page).to have_text "No products yet. Why don't you add some?"
    end

    it "displays a select box for suppliers, with the appropriate supplier selected" do
      s1 = FactoryBot.create(:supplier_enterprise)
      s2 = FactoryBot.create(:supplier_enterprise)
      s3 = FactoryBot.create(:supplier_enterprise)
      p1 = FactoryBot.create(:product, supplier: s2)
      p2 = FactoryBot.create(:product, supplier: s3)

      visit spree.admin_products_path

      expect(page).to have_select "producer_id", with_options: [s1.name, s2.name, s3.name],
                                                 selected: s2.name
      expect(page).to have_select "producer_id", with_options: [s1.name, s2.name, s3.name],
                                                 selected: s3.name
    end

    it "displays a date input for available_on for each product, formatted to yyyy-mm-dd hh:mm:ss" do
      p1 = FactoryBot.create(:product, available_on: Date.current)
      p2 = FactoryBot.create(:product, available_on: Date.current - 1)

      visit spree.admin_products_path
      toggle_columns "Available On"

      expect(page).to have_field "available_on", with: p1.available_on.strftime("%F %T")
      expect(page).to have_field "available_on", with: p2.available_on.strftime("%F %T")
    end

    it "displays an on hand count in a span for each product" do
      p1 = FactoryBot.create(:product)
      v1 = p1.variants.first
      v1.update_attribute(:on_demand, false)
      v1.update_attribute(:on_hand, 4)

      visit spree.admin_products_path

      within "#p_#{p1.id}" do
        expect(page).to have_selector "span[name='on_hand']", text: "4"
      end
    end

    it "displays 'on demand' for any variant that is available on demand" do
      p1 = FactoryBot.create(:product)
      v1 = FactoryBot.create(:variant, product: p1, is_master: false, on_hand: 4)
      v2 = FactoryBot.create(:variant, product: p1, is_master: false, on_hand: 0, on_demand: true)

      visit spree.admin_products_path
      expect(page).to have_selector "a.view-variants", count: 1
      find("a.view-variants").click

      expect(page).to have_no_selector "span[name='on_hand']", text: "On demand"
      expect(page).to have_field "variant_on_hand", with: "4"
      expect(page).to have_no_field "variant_on_hand", with: ""
      expect(page).to have_selector "span[name='variant_on_hand']", text: "On demand"
    end

    it "displays a select box for the unit of measure for the product's variants" do
      p = FactoryBot.create(:product, variant_unit: 'weight', variant_unit_scale: 1,
                                      variant_unit_name: '')

      visit spree.admin_products_path

      expect(page).to have_select "variant_unit_with_scale", selected: "Weight (g)"
    end

    it "displays a text field for the item name when unit is set to 'Items'" do
      p = FactoryBot.create(:product, variant_unit: 'items', variant_unit_scale: nil,
                                      variant_unit_name: 'packet')

      visit spree.admin_products_path

      expect(page).to have_select "variant_unit_with_scale", selected: "Items"
      expect(page).to have_field "variant_unit_name", with: "packet"
    end
  end

  describe "listing variants" do
    before do
      login_as_admin
    end

    it "displays a list of variants for each product" do
      v1 = FactoryBot.create(:variant, display_name: "something1" )
      v2 = FactoryBot.create(:variant, display_name: "something2" )

      visit spree.admin_products_path
      expect(page).to have_selector "a.view-variants", count: 2
      all("a.view-variants").each(&:click)

      expect(page).to have_field "product_name", with: v1.product.name
      expect(page).to have_field "product_name", with: v2.product.name
      expect(page).to have_field "variant_display_name", with: v1.display_name
      expect(page).to have_field "variant_display_name", with: v2.display_name
    end

    it "displays an on_hand input (for each variant) for each product" do
      p1 = FactoryBot.create(:product)
      v0 = p1.variants.first
      v0.update_attribute(:on_demand, false)
      v1 = FactoryBot.create(:variant, product: p1, is_master: false, on_hand: 15)
      v1.update_attribute(:on_demand, false)
      p1.variants << v1
      v2 = FactoryBot.create(:variant, product: p1, is_master: false, on_hand: 6)
      v2.update_attribute(:on_demand, false)
      p1.variants << v2

      visit spree.admin_products_path
      expect(page).to have_selector "a.view-variants", count: 1
      all("a.view-variants").each(&:click)

      expect(page).to have_selector "span[name='on_hand']",
                                    text: p1.variants.to_a.sum(&:on_hand).to_s
      expect(page).to have_field "variant_on_hand", with: "15"
      expect(page).to have_field "variant_on_hand", with: "6"
    end

    it "displays a price input (for each variant) for each product" do
      p1 = FactoryBot.create(:product, price: 2.0)
      v1 = FactoryBot.create(:variant, product: p1, is_master: false, price: 12.75)
      v2 = FactoryBot.create(:variant, product: p1, is_master: false, price: 2.50)

      visit spree.admin_products_path
      expect(page).to have_selector "a.view-variants", count: 1
      all("a.view-variants").each(&:click)

      expect(page).to have_field "price", with: "2.0", visible: false
      expect(page).to have_field "variant_price", with: "12.75"
      expect(page).to have_field "variant_price", with: "2.5"
    end

    it "displays a unit value field (for each variant) for each product" do
      p1 = FactoryBot.create(:product, price: 2.0, variant_unit: "weight",
                                       variant_unit_scale: "1000")
      v1 = FactoryBot.create(:variant, product: p1, is_master: false, price: 12.75,
                                       unit_value: 1200, unit_description: "(small bag)", display_as: "bag")
      v2 = FactoryBot.create(:variant, product: p1, is_master: false, price: 2.50,
                                       unit_value: 4800, unit_description: "(large bag)", display_as: "bin")

      visit spree.admin_products_path
      expect(page).to have_selector "a.view-variants", count: 1
      all("a.view-variants").each(&:click)

      expect(page).to have_field "variant_unit_value_with_description", with: "1.2 (small bag)"
      expect(page).to have_field "variant_unit_value_with_description", with: "4.8 (large bag)"
      expect(page).to have_field "variant_display_as", with: "bag"
      expect(page).to have_field "variant_display_as", with: "bin"
    end

    context "with variant overrides" do
      let!(:product) { create(:product) }
      let(:variant) { product.variants.first }
      let(:hub) { create(:distributor_enterprise) }
      let!(:override) { create(:variant_override, variant: variant, hub: hub ) }
      let(:variant_overrides_tip) {
        "This variant has %d override(s)" % 1
      }

      it "displays an icon indicating a variant has overrides" do
        visit spree.admin_products_path

        find("a.view-variants").click

        within "tr#v_#{variant.id}" do
          expect(page).to have_selector(
            "span.icon-warning-sign[data-powertip='#{variant_overrides_tip}']"
          )
        end
      end
    end
  end

  it "creating a new product" do
    create(:stock_location, backorderable_default: false)

    supplier = create(:supplier_enterprise)
    distributor = create(:distributor_enterprise)
    shipping_category = create(:shipping_category)
    taxon = create(:taxon)

    login_as_admin_and_visit spree.admin_products_path

    find("a", text: "NEW PRODUCT").click
    expect(page).to have_content 'NEW PRODUCT'

    fill_in 'product_name', with: 'Big Bag Of Apples'
    select supplier.name, from: 'product_supplier_id'
    select 'Weight (g)', from: 'product_variant_unit_with_scale'
    fill_in 'product_unit_value', with: '100'
    fill_in 'product_price', with: '10.00'
    select taxon.name, from: 'product_primary_taxon_id'
    select shipping_category.name, from: 'product_shipping_category_id'
    click_button 'Create'

    expect(URI.parse(current_url).path).to eq spree.admin_products_path
    expect(flash_message).to eq 'Product "Big Bag Of Apples" has been successfully created!'
    expect(page).to have_field "product_name", with: 'Big Bag Of Apples'
  end

  context "creating new variants" do
    before do
      # Given a product without variants or a unit
      p = FactoryBot.create(:product, variant_unit: 'weight', variant_unit_scale: 1000)
      login_as_admin
      visit spree.admin_products_path

      # I should see an add variant button
      page.find('a.view-variants').click
    end

    it "handle the default behaviour" do
      # When I add three variants
      page.find('a.add-variant').click
      page.find('a.add-variant').click

      # They should be added, and should not see edit buttons for new variants
      expect(page).to have_selector "tr.variant", count: 3
      expect(page).to have_selector "a.edit-variant", count: 1

      # When I remove two, they should be removed
      accept_alert do
        page.all('a.delete-variant').first.click
      end
      expect(page).to have_selector "tr.variant", count: 2
      page.all('a.delete-variant').first.click
      expect(page).to have_selector "tr.variant", count: 1

      # When I fill out variant details and hit update
      fill_in "variant_display_name", with: "Case of 12 Bottles"
      fill_in "variant_unit_value_with_description", with: "3 (12x250 mL bottles)"
      fill_in "variant_display_as", with: "Case"
      fill_in "variant_price", with: "4.0"
      fill_in "variant_on_hand", with: "10"

      click_button 'Save Changes', match: :first
      expect(page.find("#status-message")).to have_content "Changes saved."

      updated_variant = Spree::Variant.where(deleted_at: nil).last
      expect(updated_variant.display_name).to eq "Case of 12 Bottles"
      expect(updated_variant.unit_value).to eq 3000
      expect(updated_variant.unit_description).to eq "(12x250 mL bottles)"
      expect(updated_variant.display_as).to eq "Case"
      expect(updated_variant.price).to eq 4.0
      expect(updated_variant.on_hand).to eq 10

      # Then I should see edit buttons for the new variant
      expect(page).to have_selector "a.edit-variant"
    end

    context "handle the 'on_demand' variant case creation" do
      before do
        p = Spree::Product.first
        p.master.update_attribute(:on_hand, 5)
        p.save
        v1 = FactoryBot.create(:variant, product: p, is_master: false, on_hand: 4)
        v2 = FactoryBot.create(:variant, product: p, is_master: false, on_demand: true)
        p.variants << v1
        p.variants << v2
      end

      it "when variant unit value is: '120'" do
        within "tr#v_#{Spree::Variant.second.id}" do
          page.find(".add-variant").click
        end

        within "tr#v_-1" do
          fill_in "variant_unit_value_with_description", with: "120"
          fill_in "variant_price", with: "6.66"
        end

        click_button 'Save Changes', match: :first
        expect(page.find("#status-message")).to have_content "Changes saved."
      end

      it "creating a variant with unit value is: '120g' and 'on_hand' filled" do
        within "tr#v_#{Spree::Variant.second.id}" do
          page.find(".add-variant").click
        end

        within "tr#v_-1" do
          fill_in "variant_unit_value_with_description", with: "120g"
          fill_in "variant_price", with: "6.66"
          fill_in "variant_on_hand", with: "222"
        end

        click_button 'Save Changes', match: :first
        expect(page.find("#status-message")).to have_content "Unit value can't be blank Unit value is not a number"
      end

      it "creating a variant with unit value is: '120g' and 'on_demand' checked" do
        within "tr#v_#{Spree::Variant.second.id}" do
          page.find(".add-variant").trigger("click")
        end

        within "tr#v_-1" do
          fill_in "variant_unit_value_with_description", with: "120g"
          fill_in "variant_price", with: "6.66"
          check "variant_on_demand"
        end

        click_button 'Save Changes', match: :first
        expect(page.find("#status-message")).to have_content "Unit value can't be blank Unit value is not a number"
      end
    end
  end

  it "updating product attributes" do
    s1 = FactoryBot.create(:supplier_enterprise)
    s2 = FactoryBot.create(:supplier_enterprise)
    t1 = FactoryBot.create(:taxon)
    t2 = FactoryBot.create(:taxon)
    p = FactoryBot.create(:product, supplier: s1, available_on: Date.current,
                                    variant_unit: 'volume', variant_unit_scale: 1, primary_taxon: t2, sku: "OLD SKU")

    login_as_admin
    visit spree.admin_products_path

    toggle_columns "Available On", /^Category?/i, "Inherits Properties?", "SKU"

    within "tr#p_#{p.id}" do
      expect(page).to have_field "product_name", with: p.name
      expect(page).to have_select "producer_id", selected: s1.name
      expect(page).to have_field "available_on", with: p.available_on.strftime("%F %T")
      expect(page).to have_select2 "p#{p.id}_category_id", selected: t2.name
      expect(page).to have_select "variant_unit_with_scale", selected: "Volume (L)"
      expect(page).to have_checked_field "inherits_properties"
      expect(page).to have_field "product_sku", with: p.sku

      fill_in "product_name", with: "Big Bag Of Potatoes"
      select s2.name, from: 'producer_id'
      fill_in "available_on", with: 3.days.ago.beginning_of_day.strftime("%F %T")
      select "Weight (kg)", from: "variant_unit_with_scale"
      select2_select t1.name, from: "p#{p.id}_category_id"
      uncheck "inherits_properties"
      fill_in "product_sku", with: "NEW SKU"
    end

    click_button 'Save Changes', match: :first
    expect(page.find("#status-message")).to have_content "Changes saved."

    p.reload
    expect(p.name).to eq "Big Bag Of Potatoes"
    expect(p.supplier).to eq s2
    expect(p.variant_unit).to eq "weight"
    expect(p.variant_unit_scale).to eq 1000 # Kg
    expect(p.available_on).to eq 3.days.ago.beginning_of_day
    expect(p.primary_taxon.permalink).to eq t1.permalink
    expect(p.inherits_properties).to be false
    expect(p.sku).to eq "NEW SKU"
  end

  it "updating a product with a variant unit of 'items'" do
    p = FactoryBot.create(:product, variant_unit: 'weight', variant_unit_scale: 1000)

    login_as_admin
    visit spree.admin_products_path

    expect(page).to have_select "variant_unit_with_scale", selected: "Weight (kg)"

    select "Items", from: "variant_unit_with_scale"
    fill_in "variant_unit_name", with: "loaf"

    click_button 'Save Changes', match: :first
    expect(page.find("#status-message")).to have_content "Changes saved."

    p.reload
    expect(p.variant_unit).to eq "items"
    expect(p.variant_unit_scale).to be_nil
    expect(p.variant_unit_name).to eq "loaf"
  end

  it "updating a product with variants" do
    s1 = FactoryBot.create(:supplier_enterprise)
    s2 = FactoryBot.create(:supplier_enterprise)
    p = FactoryBot.create(:product, supplier: s1, available_on: Date.current, variant_unit: 'volume', variant_unit_scale: 0.001,
                                    price: 3.0, unit_value: 0.25, unit_description: '(bottle)' )
    v = p.variants.first
    v.update_attribute(:sku, "VARIANTSKU")
    v.update_attribute(:on_demand, false)
    v.update_attribute(:on_hand, 9)

    login_as_admin
    visit spree.admin_products_path
    expect(page).to have_selector "a.view-variants", count: 1
    find("a.view-variants").click

    toggle_columns "SKU"

    expect(page).to have_field "variant_sku", with: "VARIANTSKU"
    expect(page).to have_field "variant_price", with: "3.0"
    expect(page).to have_field "variant_unit_value_with_description", with: "250 (bottle)"
    expect(page).to have_field "variant_on_hand", with: "9"
    expect(page).to have_selector "span[name='on_hand']", text: "9"

    select "Volume (L)", from: "variant_unit_with_scale"
    fill_in "variant_sku", with: "NEWSKU"
    fill_in "variant_price", with: "4.0"
    fill_in "variant_on_hand", with: "10"
    fill_in "variant_unit_value_with_description", with: "2 (8x250 mL bottles)"

    expect(page).to have_selector "span[name='on_hand']", text: "10"

    click_button 'Save Changes', match: :first
    expect(page.find("#status-message")).to have_content "Changes saved."

    v.reload
    expect(v.sku).to eq "NEWSKU"
    expect(v.price).to eq 4.0
    expect(v.on_hand).to eq 10
    expect(v.unit_value).to eq 2 # 2L in L
    expect(v.unit_description).to eq "(8x250 mL bottles)"
  end

  it "updating delegated attributes of variants in isolation" do
    p = FactoryBot.create(:product)
    v = FactoryBot.create(:variant, product: p, price: 3.0)

    login_as_admin
    visit spree.admin_products_path
    expect(page).to have_selector "a.view-variants", count: 1
    find("a.view-variants").click

    expect(page).to have_field "variant_price", with: "3.0"

    within "#v_#{v.id}" do
      fill_in "variant_price", with: "10.0"
    end

    within "#save-bar" do
      click_button 'Save Changes'
    end

    expect(page.find("#status-message")).to have_content "Changes saved."

    v.reload
    expect(v.price).to eq 10.0
  end

  it "updating a product mutiple times without refresh" do
    p = FactoryBot.create(:product, name: 'original name')
    login_as_admin

    visit spree.admin_products_path

    expect(page).to have_field "product_name", with: "original name"

    fill_in "product_name", with: "new name 1"

    within "#save-bar" do
      click_button 'Save Changes'
    end

    expect(page.find("#status-message")).to have_content "Changes saved."
    p.reload
    expect(p.name).to eq "new name 1"

    fill_in "product_name", with: "new name 2"

    click_button 'Save Changes', match: :first
    expect(page.find("#status-message")).to have_content "Changes saved."
    p.reload
    expect(p.name).to eq "new name 2"

    fill_in "product_name", with: "original name"

    click_button 'Save Changes', match: :first
    expect(page.find("#status-message")).to have_content "Changes saved."
    p.reload
    expect(p.name).to eq "original name"
  end

  it "updating a product after cloning a product" do
    p = FactoryBot.create(:product, name: "product 1")
    login_as_admin

    visit spree.admin_products_path

    expect(page).to have_selector "a.clone-product", count: 1
    find("a.clone-product").click
    expect(page).to have_field "product_name", with: "COPY OF #{p.name}"

    within "#p_#{p.id}" do
      fill_in "product_name", with: "new product name"
    end

    within "#save-bar" do
      click_button 'Save Changes'
    end
    expect(page.find("#status-message")).to have_content "Changes saved."

    p.reload
    expect(p.name).to eq "new product name"
  end

  it "updating when a filter has been applied" do
    s1 = create(:supplier_enterprise)
    s2 = create(:supplier_enterprise)
    p1 = FactoryBot.create(:simple_product, name: "product1", supplier: s1)
    p2 = FactoryBot.create(:simple_product, name: "product2", supplier: s2)

    login_as_admin_and_visit spree.admin_products_path

    select2_select s1.name, from: "producer_filter"
    apply_filters

    sleep 2 # wait for page to initialise

    expect(page).to have_no_field "product_name", with: p2.name
    fill_in "product_name", with: "new product1"

    within "#save-bar" do
      click_button 'Save Changes'
    end

    expect(page.find("#status-message")).to have_content "Changes saved."
    p1.reload
    expect(p1.name).to eq "new product1"
  end

  describe "using action buttons" do
    describe "using delete buttons" do
      let!(:p1) { FactoryBot.create(:product) }
      let!(:p2) { FactoryBot.create(:product) }
      let!(:v1) { p1.variants.first }
      let!(:v2) { p2.variants.first }
      let!(:v3) { FactoryBot.create(:variant, product: p2 ) }

      before do
        login_as_admin
        visit spree.admin_products_path
      end

      it "shows a delete button for products, which deletes the appropriate product when clicked" do
        expect(page).to have_selector "a.delete-product", count: 2

        within "tr#p_#{p1.id}" do
          accept_alert do
            find("a.delete-product").click
          end
        end

        expect(page).to have_selector "a.delete-product", count: 1

        visit spree.admin_products_path

        expect(page).to have_selector "a.delete-product", count: 1
      end

      it "shows a delete button for variants, which deletes the appropriate variant when clicked" do
        expect(page).to have_selector "a.view-variants"
        all("a.view-variants").each(&:click)

        expect(page).to have_selector "a.delete-variant", count: 3

        within "tr#v_#{v3.id}" do
          accept_alert do
            find("a.delete-variant").click
          end
        end

        expect(page).to have_selector "a.delete-variant", count: 2

        visit spree.admin_products_path
        expect(page).to have_selector "a.view-variants"
        all("a.view-variants").select(&:visible?).each(&:click)

        expect(page).to have_selector "a.delete-variant", count: 2
      end
    end

    describe "using edit buttons" do
      let!(:p1) { FactoryBot.create(:product) }
      let!(:p2) { FactoryBot.create(:product) }
      let!(:v1) { p1.variants.first }
      let!(:v2) { p2.variants.first }

      before do
        login_as_admin_and_visit spree.admin_products_path
      end

      it "shows an edit button for products, which takes the user to the standard edit page for that product" do
        expect(page).to have_selector "a.edit-product", count: 2

        within "tr#p_#{p1.id}" do
          find("a.edit-product").click
        end

        expect(URI.parse(current_url).path).to eq spree.edit_admin_product_path(v1.product.permalink)
      end

      it "shows an edit button for products, which takes the user to the standard edit page for that product, url includes selected filter" do
        expect(page).to have_selector "a.edit-product", count: 2

        # Set a filter
        select2_select p1.supplier.name, from: "producer_filter"
        apply_filters

        within "tr#p_#{p1.id}" do
          find("a.edit-product").click
        end

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_path(
          v1.product.permalink, producerFilter: p1.supplier.id
        )
      end

      it "shows an edit button for variants, which takes the user to the standard edit page for that variant" do
        expect(page).to have_selector "a.view-variants"
        all("a.view-variants").each(&:click)

        expect(page).to have_selector "a.edit-variant", count: 2

        within "tr#v_#{v1.id}" do
          find("a.edit-variant").click
        end

        uri = URI.parse(current_url)
        expect(URI.parse(current_url).path).to eq spree.edit_admin_product_variant_path(
          v1.product.permalink, v1.id
        )
      end

      it "shows an edit button for variants, which takes the user to the standard edit page for that variant, url includes selected filter" do
        expect(page).to have_selector "a.view-variants"
        all("a.view-variants").each(&:click)

        expect(page).to have_selector "a.edit-variant", count: 2

        # Set a filter
        select2_select p1.supplier.name, from: "producer_filter"
        apply_filters

        within "tr#v_#{v1.id}" do
          find("a.edit-variant").click
        end

        uri = URI.parse(current_url)
        expect("#{uri.path}?#{uri.query}").to eq spree.edit_admin_product_variant_path(
          v1.product.permalink, v1.id, producerFilter: p1.supplier.id
        )
      end
    end

    describe "using clone buttons" do
      it "shows a clone button for products, which duplicates the product and adds it to the page when clicked" do
        p1 = FactoryBot.create(:product, name: "P1")
        p2 = FactoryBot.create(:product, name: "P2")
        p3 = FactoryBot.create(:product, name: "P3")

        login_as_admin_and_visit spree.admin_products_path

        expect(page).to have_selector "a.clone-product", count: 3

        within "tr#p_#{p1.id}" do
          find("a.clone-product").click
        end
        expect(page).to have_selector "a.clone-product", count: 4
        expect(page).to have_field "product_name", with: "COPY OF #{p1.name}"
        expect(page).to have_select "producer_id", selected: p1.supplier.name.to_s

        visit spree.admin_products_path

        expect(page).to have_selector "a.clone-product", count: 4
        expect(page).to have_field "product_name", with: "COPY OF #{p1.name}"
        expect(page).to have_select "producer_id", selected: p1.supplier.name.to_s
      end
    end
  end

  describe "using the page" do
    describe "using column display dropdown" do
      it "shows a column display dropdown, which shows a list of columns when clicked" do
        FactoryBot.create(:simple_product)
        login_as_admin_and_visit spree.admin_products_path

        toggle_columns "Available On"

        expect(page).to have_selector "th", text: "NAME"
        expect(page).to have_selector "th", text: "PRODUCER"
        expect(page).to have_selector "th", text: "PRICE"
        expect(page).to have_selector "th", text: "ON HAND"
        expect(page).to have_selector "th", text: "AV. ON"

        toggle_columns /^.{0,1}Producer$/i

        expect(page).to have_no_selector "th", text: "PRODUCER"
        expect(page).to have_selector "th", text: "NAME"
        expect(page).to have_selector "th", text: "PRICE"
        expect(page).to have_selector "th", text: "ON HAND"
        expect(page).to have_selector "th", text: "AV. ON"
      end
    end

    describe "using filtering controls" do
      it "displays basic filtering controls which filter the product list" do
        s1 = create(:supplier_enterprise)
        s2 = create(:supplier_enterprise)
        p1 = FactoryBot.create(:simple_product, name: "product1", supplier: s1)
        p2 = FactoryBot.create(:simple_product, name: "product2", supplier: s2)

        login_as_admin_and_visit spree.admin_products_path

        # Page shows the filter controls
        expect(page).to have_select "producer_filter", visible: false
        expect(page).to have_select "category_filter", visible: false

        # All products are shown when no filter is selected
        expect(page).to have_field "product_name", with: p1.name
        expect(page).to have_field "product_name", with: p2.name

        # Set a filter
        select2_select s1.name, from: "producer_filter"
        apply_filters

        # Products are hidden when filtered out
        expect(page).to have_field "product_name", with: p1.name
        expect(page).to have_no_field "product_name", with: p2.name

        # Clearing filters
        click_button "Clear Filters"
        apply_filters

        # All products are shown again
        expect(page).to have_field "product_name", with: p1.name
        expect(page).to have_field "product_name", with: p2.name
      end
    end
  end

  context "as an enterprise manager" do
    let(:supplier_managed1) { create(:supplier_enterprise, name: 'Supplier Managed 1') }
    let(:supplier_managed2) { create(:supplier_enterprise, name: 'Supplier Managed 2') }
    let(:supplier_unmanaged) { create(:supplier_enterprise, name: 'Supplier Unmanaged') }
    let(:supplier_permitted) { create(:supplier_enterprise, name: 'Supplier Permitted') }
    let(:distributor_managed) { create(:distributor_enterprise, name: 'Distributor Managed') }
    let(:distributor_unmanaged) { create(:distributor_enterprise, name: 'Distributor Unmanaged') }
    let!(:product_supplied) { create(:product, supplier: supplier_managed1, price: 10.0) }
    let!(:product_not_supplied) { create(:product, supplier: supplier_unmanaged) }
    let!(:product_supplied_permitted) {
      create(:product, name: 'Product Permitted', supplier: supplier_permitted, price: 10.0)
    }
    let(:product_supplied_inactive) {
      create(:product, supplier: supplier_managed1, price: 10.0, available_on: 1.week.from_now)
    }

    let!(:supplier_permitted_relationship) do
      create(:enterprise_relationship, parent: supplier_permitted, child: supplier_managed1,
                                       permissions_list: [:manage_products])
    end

    before do
      @enterprise_user = create(:user)
      @enterprise_user.enterprise_roles.build(enterprise: supplier_managed1).save
      @enterprise_user.enterprise_roles.build(enterprise: supplier_managed2).save
      @enterprise_user.enterprise_roles.build(enterprise: distributor_managed).save

      login_to_admin_as @enterprise_user
    end

    it "shows only products that I supply" do
      visit spree.admin_products_path

      expect(page).to have_field 'product_name', with: product_supplied.name
      expect(page).to have_field 'product_name', with: product_supplied_permitted.name
      expect(page).to have_no_field 'product_name', with: product_not_supplied.name
    end

    it "shows only suppliers that I manage or have permission to" do
      visit spree.admin_products_path

      expect(page).to have_select 'producer_id',
                                  with_options: [supplier_managed1.name, supplier_managed2.name, supplier_permitted.name], selected: supplier_managed1.name
      expect(page).to have_no_select 'producer_id', with_options: [supplier_unmanaged.name]
    end

    it "shows inactive products that I supply" do
      product_supplied_inactive

      visit spree.admin_products_path

      expect(page).to have_field 'product_name', with: product_supplied_inactive.name
    end

    it "allows me to create a product" do
      taxon = create(:taxon, name: 'Fruit')
      shipping_category = create(:shipping_category)

      visit spree.admin_products_path

      find("a", text: "NEW PRODUCT").click
      expect(page).to have_content 'NEW PRODUCT'
      expect(page).to have_select 'product_supplier_id',
                                  with_options: [supplier_managed1.name, supplier_managed2.name,
                                                 supplier_permitted.name]

      within 'fieldset#new_product' do
        fill_in 'product_name', with: 'Big Bag Of Apples'
        select supplier_permitted.name, from: 'product_supplier_id'
        select 'Weight (g)', from: 'product_variant_unit_with_scale'
        fill_in 'product_unit_value', with: '100'
        fill_in 'product_price', with: '10.00'
        select taxon.name, from: 'product_primary_taxon_id'
        select shipping_category.name, from: 'product_shipping_category_id'
      end
      click_button 'Create'

      expect(URI.parse(current_url).path).to eq spree.admin_products_path
      expect(flash_message).to eq 'Product "Big Bag Of Apples" has been successfully created!'
      expect(page).to have_field "product_name", with: 'Big Bag Of Apples'
    end

    it "allows me to update a product" do
      p = product_supplied_permitted
      v = p.variants.first
      v.update_attribute(:on_demand, false)

      visit spree.admin_products_path
      toggle_columns "Available On"

      within "tr#p_#{p.id}" do
        expect(page).to have_field "product_name", with: p.name
        expect(page).to have_select "producer_id", selected: supplier_permitted.name
        expect(page).to have_field "available_on", with: p.available_on.strftime("%F %T")

        fill_in "product_name", with: "Big Bag Of Potatoes"
        select supplier_managed2.name, from: 'producer_id'
        fill_in "available_on", with: 3.days.ago.beginning_of_day.strftime("%F %T"),
                                fill_options: { clear: :backspace }
        select "Weight (kg)", from: "variant_unit_with_scale"

        find("a.view-variants").click
      end

      within "#v_#{v.id}" do
        fill_in "variant_price", with: "20"
        fill_in "variant_on_hand", with: "18"
        fill_in "variant_display_as", with: "Big Bag"
      end

      click_button 'Save Changes', match: :first
      expect(page.find("#status-message")).to have_content "Changes saved."

      p.reload
      v.reload
      expect(p.name).to eq "Big Bag Of Potatoes"
      expect(p.supplier).to eq supplier_managed2
      expect(p.variant_unit).to eq "weight"
      expect(p.variant_unit_scale).to eq 1000 # Kg
      expect(p.available_on).to eq 3.days.ago.beginning_of_day
      expect(v.display_as).to eq "Big Bag"
      expect(v.price).to eq 20.0
      expect(v.on_hand).to eq 18
    end
  end

  describe "Updating product image" do
    let!(:product) { create(:simple_product, name: "Carrots") }

    it "displays product images and image upload modal" do
      login_as_admin_and_visit spree.admin_products_path

      within "table#listing_products tr#p_#{product.id}" do
        # Displays product images
        expect(page).to have_selector "td.image"

        # Shows default image when no image set
        expect(page).to have_css "img[src='/noimage/mini.png']"
        @old_thumb_src = page.find("a.image-modal img")['src']

        # Click image
        page.find("a.image-modal").click
      end

      # Shows upload modal
      expect(page).to have_selector "div.reveal-modal"

      within "div.reveal-modal" do
        # Shows preview of current image
        expect(page).to have_css "img.preview"

        # Upload a new image file
        attach_file 'image-upload', Rails.root.join("public/500.jpg"), visible: false

        # Shows spinner whilst loading
        expect(page).to have_css ".spinner"
      end

      expect(page).to have_no_css ".spinner"
      expect(page).to have_no_selector "div.reveal-modal"

      within "table#listing_products tr#p_#{product.id}" do
        # New thumbnail is shown in image column
        @new_thumb_src = page.find("a.image-modal img")['src']
        expect(@old_thumb_src).not_to eq @new_thumb_src

        page.find("a.image-modal").click
      end

      expect(page).to have_selector "div.reveal-modal"
    end
  end

  def apply_filters
    page.find('.button.icon-search').click
  end
end
