require 'spec_helper'

feature %q{
  As an Administrator
  I want to be able to manage products in bulk
} , js: true do
  include AuthenticationWorkflow
  include WebHelper

  describe "listing products" do
    before :each do
      login_to_admin_section
    end

    it "displays a list of products" do
      p1 = FactoryGirl.create(:product)
      p2 = FactoryGirl.create(:product)

      visit '/admin/products/bulk_edit'

      expect(page).to have_field "product_name", with: p1.name, :visible => true
      expect(page).to have_field "product_name", with: p2.name, :visible => true
    end

    it "displays a message when number of products is zero" do
      visit '/admin/products/bulk_edit'

      expect(page).to have_text "No products yet. Why don't you add some?"
    end

    it "displays a select box for suppliers, with the appropriate supplier selected" do
      s1 = FactoryGirl.create(:supplier_enterprise)
      s2 = FactoryGirl.create(:supplier_enterprise)
      s3 = FactoryGirl.create(:supplier_enterprise)
      p1 = FactoryGirl.create(:product, supplier: s2)
      p2 = FactoryGirl.create(:product, supplier: s3)

      visit '/admin/products/bulk_edit'

      expect(page).to have_select "producer_id", with_options: [s1.name,s2.name,s3.name], selected: s2.name
      expect(page).to have_select "producer_id", with_options: [s1.name,s2.name,s3.name], selected: s3.name
    end

    it "displays a date input for available_on for each product, formatted to yyyy-mm-dd hh:mm:ss" do
      p1 = FactoryGirl.create(:product, available_on: Date.current)
      p2 = FactoryGirl.create(:product, available_on: Date.current-1)

      visit '/admin/products/bulk_edit'
      find("div#columns-dropdown", :text => "COLUMNS").click
      find("div#columns-dropdown div.menu div.menu_item", text: "Available On").click
      find("div#columns-dropdown", :text => "COLUMNS").click

      expect(page).to have_field "available_on", with: p1.available_on.strftime("%F %T")
      expect(page).to have_field "available_on", with: p2.available_on.strftime("%F %T")
    end

    it "displays an on hand count in a span for each product" do
      p1 = FactoryGirl.create(:product, on_hand: 15)
      v1 = p1.variants.first
      v1.on_hand = 4
      v1.save!

      visit '/admin/products/bulk_edit'

      within "#p_#{p1.id}" do
        expect(page).to have_no_field "on_hand", with: "15"
        expect(page).to have_selector "span[name='on_hand']", text: "4"
      end
    end

    it "displays 'on demand' for any variant that is available on demand" do
      p1 = FactoryGirl.create(:product)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 4)
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 0, on_demand: true)

      visit '/admin/products/bulk_edit'
      expect(page).to have_selector "a.view-variants", count: 1
      find("a.view-variants").trigger('click')

      expect(page).to have_no_selector "span[name='on_hand']", text: "On demand", visible: true
      expect(page).to     have_field "variant_on_hand", with: "4"
      expect(page).to have_no_field "variant_on_hand", with: "", visible: true
      expect(page).to     have_selector "span[name='variant_on_hand']", text: "On demand"
    end

    it "displays a select box for the unit of measure for the product's variants" do
      p = FactoryGirl.create(:product, variant_unit: 'weight', variant_unit_scale: 1, variant_unit_name: '')

      visit '/admin/products/bulk_edit'

      expect(page).to have_select "variant_unit_with_scale", selected: "Weight (g)"
    end

    it "displays a text field for the item name when unit is set to 'Items'" do
      p = FactoryGirl.create(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: 'packet')

      visit '/admin/products/bulk_edit'

      expect(page).to have_select "variant_unit_with_scale", selected: "Items"
      expect(page).to have_field "variant_unit_name", with: "packet"
    end
  end

  describe "listing variants" do
    before :each do
      login_to_admin_section
    end

    it "displays a list of variants for each product" do
      v1 = FactoryGirl.create(:variant, display_name: "something1" )
      v2 = FactoryGirl.create(:variant, display_name: "something2" )

      visit '/admin/products/bulk_edit'
      expect(page).to have_selector "a.view-variants", count: 2
      all("a.view-variants").each { |e| e.trigger('click') }

      expect(page).to have_field "product_name", with: v1.product.name
      expect(page).to have_field "product_name", with: v2.product.name
      expect(page).to have_field "variant_display_name", with: v1.display_name
      expect(page).to have_field "variant_display_name", with: v2.display_name
    end

    it "displays an on_hand input (for each variant) for each product" do
      p1 = FactoryGirl.create(:product)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 15)
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, on_hand: 6)

      visit '/admin/products/bulk_edit'
      expect(page).to have_selector "a.view-variants", count: 1
      all("a.view-variants").each { |e| e.trigger('click') }

      expect(page).to have_selector "span[name='on_hand']", text: p1.variants.sum{ |v| v.on_hand }.to_s
      expect(page).to have_field "variant_on_hand", with: "15"
      expect(page).to have_field "variant_on_hand", with: "6"
    end


    it "displays a price input (for each variant) for each product" do
      p1 = FactoryGirl.create(:product, price: 2.0)
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 12.75)
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 2.50)

      visit '/admin/products/bulk_edit'
      expect(page).to have_selector "a.view-variants", count: 1
      all("a.view-variants").each { |e| e.trigger('click') }

      expect(page).to have_field "price", with: "2.0", visible: false
      expect(page).to have_field "variant_price", with: "12.75"
      expect(page).to have_field "variant_price", with: "2.5"
    end

    it "displays a unit value field (for each variant) for each product" do
      p1 = FactoryGirl.create(:product, price: 2.0, variant_unit: "weight", variant_unit_scale: "1000")
      v1 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 12.75, unit_value: 1200, unit_description: "(small bag)", display_as: "bag")
      v2 = FactoryGirl.create(:variant, product: p1, is_master: false, price: 2.50, unit_value: 4800, unit_description: "(large bag)", display_as: "bin")

      visit '/admin/products/bulk_edit'
      expect(page).to have_selector "a.view-variants", count: 1
      all("a.view-variants").each { |e| e.trigger('click') }

      expect(page).to have_field "variant_unit_value_with_description", with: "1.2 (small bag)"
      expect(page).to have_field "variant_unit_value_with_description", with: "4.8 (large bag)"
      expect(page).to have_field "variant_display_as", with: "bag"
      expect(page).to have_field "variant_display_as", with: "bin"
    end
  end


  scenario "creating a new product" do
    s = FactoryGirl.create(:supplier_enterprise)
    d = FactoryGirl.create(:distributor_enterprise)
    taxon = create(:taxon)

    login_to_admin_section

    visit '/admin/products/bulk_edit'

    find("a", text: "NEW PRODUCT").click
    expect(page).to have_content 'NEW PRODUCT'

    fill_in 'product_name', :with => 'Big Bag Of Apples'
    select s.name, :from => 'product_supplier_id'
    select 'Weight (g)', from: 'product_variant_unit_with_scale'
    fill_in 'product_unit_value_with_description', with: '100'
    fill_in 'product_price', :with => '10.00'
    select taxon.name, from: 'product_primary_taxon_id'
    click_button 'Create'

    expect(URI.parse(current_url).path).to eq '/admin/products/bulk_edit'
    expect(flash_message).to eq 'Product "Big Bag Of Apples" has been successfully created!'
    expect(page).to have_field "product_name", with: 'Big Bag Of Apples'
  end


  scenario "creating new variants" do
    # Given a product without variants or a unit
    p = FactoryGirl.create(:product, variant_unit: 'weight', variant_unit_scale: 1000)
    login_to_admin_section
    visit '/admin/products/bulk_edit'

    # I should see an add variant button
    page.find('a.view-variants').trigger('click')

    # When I add three variants
    page.find('a.add-variant', visible: true).trigger('click')
    page.find('a.add-variant', visible: true).trigger('click')

    # They should be added, and should not see edit buttons for new variants
    expect(page).to have_selector "tr.variant", count: 3
    expect(page).to have_selector "a.edit-variant", count: 1

    # When I remove two, they should be removed
    page.all('a.delete-variant', visible: true).first.click
    expect(page).to have_selector "tr.variant", count: 2
    page.all('a.delete-variant', visible: true).first.click
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
    expect(page).to have_selector "a.edit-variant", visible: true
  end

  scenario "updating product attributes" do
    s1 = FactoryGirl.create(:supplier_enterprise)
    s2 = FactoryGirl.create(:supplier_enterprise)
    t1 = FactoryGirl.create(:taxon)
    t2 = FactoryGirl.create(:taxon)
    p = FactoryGirl.create(:product, supplier: s1, available_on: Date.current, variant_unit: 'volume', variant_unit_scale: 1, primary_taxon: t2, sku: "OLD SKU")

    login_to_admin_section

    visit '/admin/products/bulk_edit'

    find("div#columns-dropdown", :text => "COLUMNS").click
    find("div#columns-dropdown div.menu div.menu_item", text: "Available On").click
    find("div#columns-dropdown div.menu div.menu_item", text: /^Category?/).click
    find("div#columns-dropdown div.menu div.menu_item", text: "Inherits Properties?").click
    find("div#columns-dropdown div.menu div.menu_item", text: "SKU").click
    find("div#columns-dropdown", :text => "COLUMNS").click

    within "tr#p_#{p.id}" do
      expect(page).to have_field "product_name", with: p.name
      expect(page).to have_select "producer_id", selected: s1.name
      expect(page).to have_field "available_on", with: p.available_on.strftime("%F %T")
      expect(page).to have_select2 "p#{p.id}_category_id", selected: t2.name
      expect(page).to have_select "variant_unit_with_scale", selected: "Volume (L)"
      expect(page).to have_checked_field "inherits_properties"
      expect(page).to have_field "product_sku", with: p.sku

      fill_in "product_name", with: "Big Bag Of Potatoes"
      select s2.name, :from => 'producer_id'
      fill_in "available_on", with: (3.days.ago.beginning_of_day).strftime("%F %T")
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
    expect(p.primary_taxon).to eq t1
    expect(p.inherits_properties).to be false
    expect(p.sku).to eq "NEW SKU"
  end

  scenario "updating a product with a variant unit of 'items'" do
    p = FactoryGirl.create(:product, variant_unit: 'weight', variant_unit_scale: 1000)

    login_to_admin_section

    visit '/admin/products/bulk_edit'

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

  scenario "updating a product with variants" do
    s1 = FactoryGirl.create(:supplier_enterprise)
    s2 = FactoryGirl.create(:supplier_enterprise)
    p = FactoryGirl.create(:product, supplier: s1, available_on: Date.current, variant_unit: 'volume', variant_unit_scale: 0.001,
      price: 3.0, on_hand: 9, unit_value: 0.25, unit_description: '(bottle)' )
    v = p.variants.first
    v.update_column(:sku, "VARIANTSKU")

    login_to_admin_section

    visit '/admin/products/bulk_edit'
    expect(page).to have_selector "a.view-variants", count: 1
    find("a.view-variants").trigger('click')

    find("div#columns-dropdown", :text => "COLUMNS").click
    find("div#columns-dropdown div.menu div.menu_item", text: "SKU").click
    find("div#columns-dropdown", :text => "COLUMNS").click

    expect(page).to have_field "variant_sku", with: "VARIANTSKU"
    expect(page).to have_field "variant_price", with: "3.0"
    expect(page).to have_field "variant_unit_value_with_description", with: "250 (bottle)"
    expect(page).to have_field "variant_on_hand", with: "9"
    expect(page).to have_selector "span[name='on_hand']", "9"

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

  scenario "updating delegated attributes of variants in isolation" do
    p = FactoryGirl.create(:product)
    v = FactoryGirl.create(:variant, product: p, price: 3.0)

    login_to_admin_section

    visit '/admin/products/bulk_edit'
    expect(page).to have_selector "a.view-variants", count: 1
    find("a.view-variants").trigger('click')

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

  scenario "updating a product mutiple times without refresh" do
    p = FactoryGirl.create(:product, name: 'original name')
    login_to_admin_section

    visit '/admin/products/bulk_edit'

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

  scenario "updating a product after cloning a product" do
    p = FactoryGirl.create(:product, :name => "product 1")
    login_to_admin_section

    visit '/admin/products/bulk_edit'

    expect(page).to have_selector "a.clone-product", count: 1
    find("a.clone-product").click

    fill_in "product_name", :with => "new product name"

    within "#save-bar" do
      click_button 'Save Changes'
    end

    expect(page.find("#status-message")).to have_content "Changes saved."
    p.reload
    expect(p.name).to eq "new product name"
  end

  scenario "updating when a filter has been applied" do
    s1 = create(:supplier_enterprise)
    s2 = create(:supplier_enterprise)
    p1 = FactoryGirl.create(:simple_product, :name => "product1", supplier: s1)
    p2 = FactoryGirl.create(:simple_product, :name => "product2", supplier: s2)
    login_to_admin_section

    visit '/admin/products/bulk_edit'

    select2_select s1.name, from: "producer_filter"

    expect(page).to have_no_field "product_name", with: p2.name
    fill_in "product_name", :with => "new product1"

    within "#save-bar" do
      click_button 'Save Changes'
    end

    expect(page.find("#status-message")).to have_content "Changes saved."
    p1.reload
    expect(p1.name).to eq "new product1"
  end

  describe "using action buttons" do
    describe "using delete buttons" do
      let!(:p1) { FactoryGirl.create(:product) }
      let!(:p2) { FactoryGirl.create(:product) }
      let!(:v1) { p1.variants.first }
      let!(:v2) { p2.variants.first }
      let!(:v3) { FactoryGirl.create(:variant, product: p2 ) }


      before do
        quick_login_as_admin
        visit '/admin/products/bulk_edit'
      end

      it "shows a delete button for products, which deletes the appropriate product when clicked" do
        expect(page).to have_selector "a.delete-product", :count => 2

        within "tr#p_#{p1.id}" do
          find("a.delete-product").click
        end

        expect(page).to have_selector "a.delete-product", :count => 1

        visit '/admin/products/bulk_edit'

        expect(page).to have_selector "a.delete-product", :count => 1
      end

      it "shows a delete button for variants, which deletes the appropriate variant when clicked" do
        expect(page).to have_selector "a.view-variants"
        all("a.view-variants").each { |e| e.trigger('click') }

        expect(page).to have_selector "a.delete-variant", :count => 3

        within "tr#v_#{v3.id}" do
          find("a.delete-variant").click
        end

        expect(page).to have_selector "a.delete-variant", :count => 2

        visit '/admin/products/bulk_edit'
        expect(page).to have_selector "a.view-variants"
        all("a.view-variants").select { |e| e.visible? }.each { |e| e.trigger('click') }

        expect(page).to have_selector "a.delete-variant", :count => 2
      end
    end

    describe "using edit buttons" do
      let!(:p1) { FactoryGirl.create(:product) }
      let!(:p2) { FactoryGirl.create(:product) }
      let!(:v1) { p1.variants.first }
      let!(:v2) { p2.variants.first }

      before do
        quick_login_as_admin
        visit '/admin/products/bulk_edit'
      end

      it "shows an edit button for products, which takes the user to the standard edit page for that product" do
        expect(page).to have_selector "a.edit-product", :count => 2

        within "tr#p_#{p1.id}" do
          find("a.edit-product").click
        end

        expect(URI.parse(current_url).path).to eq "/admin/products/#{p1.permalink}/edit"
      end

      it "shows an edit button for variants, which takes the user to the standard edit page for that variant" do
        expect(page).to have_selector "a.view-variants"
        all("a.view-variants").each { |e| e.trigger('click') }

        expect(page).to have_selector "a.edit-variant", :count => 2

        within "tr#v_#{v1.id}" do
          find("a.edit-variant").click
        end

        expect(URI.parse(current_url).path).to eq "/admin/products/#{v1.product.permalink}/variants/#{v1.id}/edit"
      end
    end

    describe "using clone buttons" do
      it "shows a clone button for products, which duplicates the product and adds it to the page when clicked" do
        p1 = FactoryGirl.create(:product, :name => "P1")
        p2 = FactoryGirl.create(:product, :name => "P2")
        p3 = FactoryGirl.create(:product, :name => "P3")
        login_to_admin_section

        visit '/admin/products/bulk_edit'

        expect(page).to have_selector "a.clone-product", :count => 3

        within "tr#p_#{p1.id}" do
          find("a.clone-product").click
        end
        expect(page).to have_selector "a.clone-product", :count => 4
        expect(page).to have_field "product_name", with: "COPY OF #{p1.name}"
        expect(page).to have_select "producer_id", selected: "#{p1.supplier.name}"

        visit '/admin/products/bulk_edit'

        expect(page).to have_selector "a.clone-product", :count => 4
        expect(page).to have_field "product_name", with: "COPY OF #{p1.name}"
        expect(page).to have_select "producer_id", selected: "#{p1.supplier.name}"
      end
    end
  end

  describe "using the page" do
    describe "using column display dropdown" do
      it "shows a column display dropdown, which shows a list of columns when clicked" do
        FactoryGirl.create(:simple_product)
        login_to_admin_section

        visit '/admin/products/bulk_edit'

        find("div#columns-dropdown", :text => "COLUMNS").click
        find("div#columns-dropdown div.menu div.menu_item", text: "Available On").click
        find("div#columns-dropdown", :text => "COLUMNS").click

        expect(page).to have_selector "th", :text => "NAME"
        expect(page).to have_selector "th", :text => "PRODUCER"
        expect(page).to have_selector "th", :text => "PRICE"
        expect(page).to have_selector "th", :text => "ON HAND"
        expect(page).to have_selector "th", :text => "AV. ON"

        find("div#columns-dropdown", :text => "COLUMNS").click
        find("div#columns-dropdown div.menu div.menu_item", text: /^.{0,1}Producer$/).click
        find("div#columns-dropdown", :text => "COLUMNS").click

        expect(page).to have_no_selector "th", :text => "PRODUCER"
        expect(page).to have_selector "th", :text => "NAME"
        expect(page).to have_selector "th", :text => "PRICE"
        expect(page).to have_selector "th", :text => "ON HAND"
        expect(page).to have_selector "th", :text => "AV. ON"
      end
    end

    describe "using filtering controls" do
      it "displays basic filtering controls which filter the product list" do
        s1 = create(:supplier_enterprise)
        s2 = create(:supplier_enterprise)
        p1 = FactoryGirl.create(:simple_product, :name => "product1", supplier: s1)
        p2 = FactoryGirl.create(:simple_product, :name => "product2", supplier: s2)
        login_to_admin_section

        visit '/admin/products/bulk_edit'

        # Page shows the filter controls
        expect(page).to have_select "producer_filter", visible: false
        expect(page).to have_select "category_filter", visible: false

        # All products are shown when no filter is selected
        expect(page).to have_field "product_name", with: p1.name
        expect(page).to have_field "product_name", with: p2.name

        # Set a filter
        select2_select s1.name, from: "producer_filter"

        # Products are hidden when filtered out
        expect(page).to have_field "product_name", with: p1.name
        expect(page).to have_no_field "product_name", with: p2.name

        # Clearing filters
        click_button "Clear Filters"

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
    let!(:product_supplied) { create(:product, supplier: supplier_managed1, price: 10.0, on_hand: 6) }
    let!(:product_not_supplied) { create(:product, supplier: supplier_unmanaged) }
    let!(:product_supplied_permitted) { create(:product, name: 'Product Permitted', supplier: supplier_permitted, price: 10.0, on_hand: 6) }
    let(:product_supplied_inactive) { create(:product, supplier: supplier_managed1, price: 10.0, on_hand: 6, available_on: 1.week.from_now) }

    let!(:supplier_permitted_relationship) do
      create(:enterprise_relationship, parent: supplier_permitted, child: supplier_managed1,
             permissions_list: [:manage_products])
    end

    before do
      @enterprise_user = create_enterprise_user
      @enterprise_user.enterprise_roles.build(enterprise: supplier_managed1).save
      @enterprise_user.enterprise_roles.build(enterprise: supplier_managed2).save
      @enterprise_user.enterprise_roles.build(enterprise: distributor_managed).save

      login_to_admin_as @enterprise_user
    end

    it "shows only products that I supply" do
      visit '/admin/products/bulk_edit'

      expect(page).to have_field 'product_name', with: product_supplied.name
      expect(page).to have_field 'product_name', with: product_supplied_permitted.name
      expect(page).to have_no_field 'product_name', with: product_not_supplied.name
    end

    it "shows only suppliers that I manage or have permission to" do
      visit '/admin/products/bulk_edit'

      expect(page).to have_select 'producer_id', with_options: [supplier_managed1.name, supplier_managed2.name, supplier_permitted.name], selected: supplier_managed1.name
      expect(page).to have_no_select 'producer_id', with_options: [supplier_unmanaged.name]
    end

    it "shows inactive products that I supply" do
      product_supplied_inactive

      visit '/admin/products/bulk_edit'

      expect(page).to have_field 'product_name', with: product_supplied_inactive.name
    end

    it "allows me to create a product" do
      taxon = create(:taxon, name: 'Fruit')

      visit '/admin/products/bulk_edit'

      find("a", text: "NEW PRODUCT").click
      expect(page).to have_content 'NEW PRODUCT'
      expect(page).to have_select 'product_supplier_id', with_options: [supplier_managed1.name, supplier_managed2.name, supplier_permitted.name]

      within 'fieldset#new_product' do
        fill_in 'product_name', with: 'Big Bag Of Apples'
        select supplier_permitted.name, from: 'product_supplier_id'
        select 'Weight (g)', from: 'product_variant_unit_with_scale'
        fill_in 'product_unit_value_with_description', with: '100'
        fill_in 'product_price', with: '10.00'
        select taxon.name, from: 'product_primary_taxon_id'
      end
      click_button 'Create'

      expect(URI.parse(current_url).path).to eq '/admin/products/bulk_edit'
      expect(flash_message).to eq 'Product "Big Bag Of Apples" has been successfully created!'
      expect(page).to have_field "product_name", with: 'Big Bag Of Apples'
    end

    it "allows me to update a product" do
      p = product_supplied_permitted
      v = p.variants.first

      visit '/admin/products/bulk_edit'
      find("div#columns-dropdown", :text => "COLUMNS").click
      find("div#columns-dropdown div.menu div.menu_item", text: "Available On").click
      find("div#columns-dropdown", :text => "COLUMNS").click

      within "tr#p_#{p.id}" do
        expect(page).to have_field "product_name", with: p.name
        expect(page).to have_select "producer_id", selected: supplier_permitted.name
        expect(page).to have_field "available_on", with: p.available_on.strftime("%F %T")

        fill_in "product_name", with: "Big Bag Of Potatoes"
        select supplier_managed2.name, :from => 'producer_id'
        fill_in "available_on", with: (3.days.ago.beginning_of_day).strftime("%F %T")
        select "Weight (kg)", from: "variant_unit_with_scale"

        find("a.view-variants").trigger('click')
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
end
