# frozen_string_literal: true

require "system_helper"

RSpec.describe 'As an enterprise user, I can manage my products', feature: :admin_style_v3 do
  include AdminHelper
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  let(:producer) { create(:supplier_enterprise) }
  let(:user) { create(:user, enterprises: [producer]) }

  before do
    login_as user
  end

  let(:producer_search_selector) { 'input[placeholder="Search for producers"]' }
  let(:categories_search_selector) { 'input[placeholder="Search for categories"]' }
  let(:tax_categories_search_selector) { 'input[placeholder="Search for tax categories"]' }

  describe "with no products" do
    before { visit admin_products_url }
    it "can see the new product page" do
      expect(page).to have_content "Bulk Edit Products"
      expect(page).to have_text "No products found"
      # displays buttons to add products with the correct links
      expect(page).to have_link(class: "button", text: "New Product", href: "/admin/products/new")
      expect(page).to have_link(class: "button", text: "Import multiple products",
                                href: "/admin/products/import")
    end
  end

  describe "column selector" do
    let!(:product) { create(:simple_product) }

    before do
      visit admin_products_url
    end

    it "hides column and remembers saved preference" do
      # Name shows by default
      expect(page).to have_checked_field "Name"
      expect(page).to have_selector "th", text: "Name"
      expect_other_columns_visible

      # Name is hidden
      ofn_drop_down("Columns").click
      within ofn_drop_down("Columns") do
        uncheck "Name"
      end
      expect(page).not_to have_selector "th", text: "Name"
      expect_other_columns_visible

      # Preference saved
      click_on "Save as default"
      expect(page).to have_content "Column preferences saved"
      refresh

      # Preference remembered
      ofn_drop_down("Columns").click
      within ofn_drop_down("Columns") do
        expect(page).to have_unchecked_field "Name"
      end
      expect(page).not_to have_selector "th", text: "Name"
      expect_other_columns_visible
    end

    def expect_other_columns_visible
      expect(page).to have_selector "th", text: "Producer"
      expect(page).to have_selector "th", text: "Price"
      expect(page).to have_selector "th", text: "On Hand"
    end
  end

  describe "columns"

  describe "Changing producers, category and tax category" do
    let!(:variant_a1) {
      product_a.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "APL-01", price: 5.25, on_hand: 5,
                  on_demand: false
      }
    }
    let!(:product_a) {
      create(:simple_product, name: "Apples", sku: "APL-00",
                              variant_unit: "weight", variant_unit_scale: 1) # Grams
    }

    context "when they are under 11" do
      before do
        create_list(:supplier_enterprise, 9, users: [user])
        create_list(:tax_category, 9)
        create_list(:taxon, 2)

        visit admin_products_url
      end

      it "should not display search input, change the producers, category and tax category" do
        producer_to_select = random_producer(variant_a1)
        category_to_select = random_category(variant_a1)
        tax_category_to_select = random_tax_category

        within row_containing_name(variant_a1.display_name) do
          validate_tomselect_without_search!(
            page, "Producer",
            producer_search_selector
          )
          tomselect_select(producer_to_select, from: "Producer")
        end

        within row_containing_name(variant_a1.display_name) do
          validate_tomselect_without_search!(
            page, "Category",
            categories_search_selector
          )
          tomselect_select(category_to_select, from: "Category")

          validate_tomselect_without_search!(
            page, "Tax Category",
            tax_categories_search_selector
          )
          tomselect_select(tax_category_to_select, from: "Tax Category")
        end

        click_button "Save changes"

        expect(page).to have_content "Changes saved"

        variant_a1.reload
        expect(variant_a1.supplier.name).to eq(producer_to_select)
        expect(variant_a1.primary_taxon.name).to eq(category_to_select)
        expect(variant_a1.tax_category.name).to eq(tax_category_to_select)
      end
    end

    context "when they are over 11" do
      before do
        create_list(:supplier_enterprise, 11, users: [user])
        create_list(:tax_category, 11)
        create_list(:taxon, 11)

        visit admin_products_url
      end

      it "should display search input, change the producer" do
        producer_to_select = random_producer(variant_a1)
        category_to_select = random_category(variant_a1)
        tax_category_to_select = random_tax_category

        within row_containing_name(variant_a1.display_name) do
          validate_tomselect_with_search!(
            page, "Producer",
            producer_search_selector
          )
          tomselect_search_and_select(producer_to_select, from: "Producer")

          sleep(0.1)
          validate_tomselect_with_search!(
            page, "Category",
            categories_search_selector
          )
          tomselect_search_and_select(category_to_select, from: "Category")

          sleep(0.1)
          validate_tomselect_with_search!(
            page, "Tax Category",
            tax_categories_search_selector
          )
          tomselect_search_and_select(tax_category_to_select, from: "Tax Category")
        end

        click_button "Save changes"

        expect(page).to have_content "Changes saved"

        variant_a1.reload
        expect(variant_a1.supplier.name).to eq(producer_to_select)
        expect(variant_a1.primary_taxon.name).to eq(category_to_select)
        expect(variant_a1.tax_category.name).to eq(tax_category_to_select)
      end
    end
  end

  describe "actions" do
    describe "edit" do
      let!(:variant_a1) {
        create(:variant,
               product: product_a,
               display_name: "Medium box",
               sku: "APL-01",
               price: 5.25)
      }
      let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }

      before do
        visit admin_products_url
      end

      it "shows an actions menu with an edit link for product and variant" do
        within row_containing_name("Apples") do
          page.find(".vertical-ellipsis-menu").click
          expect(page).to have_link "Edit", href: spree.edit_admin_product_path(product_a)
        end

        within row_containing_name("Medium box") do
          page.find(".vertical-ellipsis-menu").click
          expect(page).to have_link "Edit",
                                    href: spree.edit_admin_product_variant_path(product_a,
                                                                                variant_a1)
        end
      end
    end

    describe "clone" do
      let!(:variant_a1) {
        create(:variant,
               product: product_a,
               display_name: "Medium box",
               sku: "APL-01",
               price: 5.25)
      }
      let(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }

      before do
        visit admin_products_url
      end

      describe "Actions columns (clone)" do
        it "shows an actions menu with a clone link when clicking on icon for product" do
          within row_containing_name("Apples") do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_link "Clone", href: admin_clone_product_path(product_a)
          end

          within row_containing_name("Medium box") do
            page.find(".vertical-ellipsis-menu").click
            expect(page).not_to have_link "Clone", href: admin_clone_product_path(product_a)
          end
        end
      end

      describe "Cloning product" do
        it "shows the cloned product on page when clicked on the cloned option" do
          # TODO, variant supplier missing, needs to be copied from variant and not product
          within "table.products" do
            # Gather input values, because page.content doesn't include them.
            input_content = page.find_all('input[type=text]').map(&:value).join

            # Products does not include the cloned product.
            expect(input_content).not_to match /COPY OF Apples/
          end

          click_product_clone "Apples"

          expect(page).to have_content "Successfully cloned the product"
          within "table.products" do
            # Gather input values, because page.content doesn't include them.
            input_content = page.find_all('input[type=text]').map(&:value).join

            # Products include the cloned product.
            expect(input_content).to match /COPY OF Apples/
          end
        end

        it "shows error message when cloning invalid record" do
          # Existing product is invalid:
          product_a.update_columns(variant_unit: nil)

          click_product_clone "Apples"

          expect(page).to have_content "Unable to clone the product"

          within "table.products" do
            # Products does not include the cloned product.
            expect(all_input_values).not_to match /COPY OF Apples/
          end
        end
      end
    end

    describe "delete" do
      let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }
      let(:delete_option_selector) { "a[data-controller='modal-link'].delete" }
      let(:product_selector) { row_containing_name("Apples") }
      let(:variant_selector) { row_containing_name("Medium box") }
      let(:default_variant_selector) {
        "tr:has(input[aria-label=Price][value='#{product_a.price}'])"
      }

      describe "Actions columns (delete)" do
        before do
          visit admin_products_url
        end

        it "shows an actions menu with a delete link when clicking on icon for product. " \
           "doesn't show delete link for the single variant" do
          within product_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_css(delete_option_selector)
          end
          page.find("div#content").click # to close the vertical actions menu

          # to select the default variant
          within default_variant_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).not_to have_css(delete_option_selector)
          end
        end

        it "shows an actions menu with a delete link when clicking on icon for variant " \
           "if have multiple" do
          create(:variant,
                 product: product_a,
                 display_name: "Medium box",
                 sku: "APL-01",
                 price: 5.25)
          visit admin_products_url

          # to select the default variant
          within default_variant_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_css(delete_option_selector)
          end
          page.find("div#content").click # to close the vertical actions menu

          within variant_selector do
            page.find(".vertical-ellipsis-menu").click
            expect(page).to have_css(delete_option_selector)
          end
        end
      end

      describe "Delete Action" do
        let!(:variant_a1) {
          create(:variant,
                 product: product_a,
                 display_name: "Medium box",
                 sku: "APL-01",
                 price: 5.25)
        }
        let(:modal_selector) { "div[data-modal-target=modal]" }
        let(:dismiss_button_selector) { "button[data-action='click->flash#close']" }

        context "when 'keep product/variant' is selected" do
          it 'should not delete the product/variant' do
            visit admin_products_url

            # Keep Product
            within product_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            keep_button_selector = "input[type=button][value='Keep product']"
            within modal_selector do
              page.find(keep_button_selector).click
            end

            expect(page).not_to have_selector(modal_selector)
            expect(page).to have_selector(product_selector)

            # Keep Variant
            within variant_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            keep_button_selector = "input[type=button][value='Keep variant']"
            within modal_selector do
              page.find(keep_button_selector).click
            end

            expect(page).not_to have_selector(modal_selector)
            expect(page).to have_selector(variant_selector)
          end
        end

        context "when 'delete product/variant' is selected" do
          let(:success_flash_message_selector) { "div.flash.success" }
          let(:error_flash_message_selector) { "div.flash.error" }
          it 'should successfully delete the product/variant' do
            visit admin_products_url
            # Delete Variant
            within variant_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end

            delete_button_selector = "input[type=button][value='Delete variant']"
            within modal_selector do
              page.find(delete_button_selector).click
            end

            expect(page).not_to have_selector(modal_selector)
            expect(page).not_to have_selector(variant_selector)
            within success_flash_message_selector do
              expect(page).to have_content("Successfully deleted the variant")
              page.find(dismiss_button_selector).click
            end

            # Delete product
            within product_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            delete_button_selector = "input[type=button][value='Delete product']"
            within modal_selector do
              page.find(delete_button_selector).click
            end
            expect(page).not_to have_selector(modal_selector)
            expect(page).not_to have_selector(product_selector)
            within success_flash_message_selector do
              expect(page).to have_content("Successfully deleted the product")
            end
          end

          it 'should be failed to delete the product/variant' do
            visit admin_products_url
            allow_any_instance_of(Spree::Product).to receive(:destroy).and_return(false)
            allow_any_instance_of(Spree::Variant).to receive(:destroy).and_return(false)

            # Delete Variant
            within variant_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end

            delete_button_selector = "input[type=button][value='Delete variant']"
            within modal_selector do
              page.find(delete_button_selector).click
            end

            within error_flash_message_selector do
              expect(page).to have_content("Unable to delete the variant")
              page.find(dismiss_button_selector).click
            end

            # Delete product
            within product_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            delete_button_selector = "input[type=button][value='Delete product']"
            within modal_selector do
              page.find(delete_button_selector).click
            end
            within error_flash_message_selector do
              expect(page).to have_content("Unable to delete the product")
            end
          end
        end

        context 'a shipped product' do
          let!(:order) { create(:shipped_order, line_items_count: 1) }
          let!(:line_item) { order.reload.line_items.first }

          context "a deleted line item from a shipped order" do
            before do
              login_as_admin
              visit admin_products_url

              # Delete Variant
              within variant_selector do
                page.find(".vertical-ellipsis-menu").click
                page.find(delete_option_selector).click
              end

              delete_button_selector = "input[type=button][value='Delete variant']"
              within modal_selector do
                page.find(delete_button_selector).click
              end
            end

            it 'keeps the line item on the order (admin)' do
              visit spree.edit_admin_order_path(order)

              expect(page).to have_content(line_item.product.name.to_s)
            end
          end
        end
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
    let!(:product_supplied) { create(:product, supplier_id: supplier_managed1.id, price: 10.0) }
    let!(:product_not_supplied) { create(:product, supplier_id: supplier_unmanaged.id) }
    let!(:product_supplied_permitted) {
      create(:product, name: 'Product Permitted', supplier_id: supplier_permitted.id, price: 10.0)
    }
    let(:product_supplied_inactive) {
      create(:product, supplier_id: supplier_managed1.id, price: 10.0)
    }

    let!(:supplier_permitted_relationship) do
      create(:enterprise_relationship, parent: supplier_permitted, child: supplier_managed1,
                                       permissions_list: [:manage_products])
    end

    before do
      enterprise_user = create(:user)
      enterprise_user.enterprise_roles.build(enterprise: supplier_managed1).save
      enterprise_user.enterprise_roles.build(enterprise: supplier_managed2).save
      enterprise_user.enterprise_roles.build(enterprise: distributor_managed).save

      login_as enterprise_user
    end

    it "shows only products that I supply" do
      visit spree.admin_products_path

      # displays permitted product list only
      expect(page).to have_selector row_containing_name(product_supplied.name)
      expect(page).to have_selector row_containing_name(product_supplied_permitted.name)
      expect(page).not_to have_selector row_containing_name(product_not_supplied.name)
    end

    it "shows only suppliers that I manage or have permission to" do
      visit spree.admin_products_path
      within row_containing_name(product_supplied.name) do
        expect(page).to have_select(
          '_products_0_supplier_id',
          options: [
            supplier_managed1.name, supplier_managed2.name, supplier_permitted.name
          ], selected: supplier_managed1.name
        )
      end

      within row_containing_name(product_supplied_permitted.name) do
        expect(page).to have_select(
          '_products_1_supplier_id',
          options: [
            supplier_managed1.name, supplier_managed2.name, supplier_permitted.name
          ], selected: supplier_permitted.name
        )
      end
    end

    it "shows inactive products that I supply" do
      product_supplied_inactive

      visit spree.admin_products_path

      expect(page).to have_selector row_containing_name(product_supplied_inactive.name)
    end

    it "allows me to update a product" do
      visit spree.admin_products_path

      within row_containing_name(product_supplied.name) do
        fill_in "Name", with: "Pommes"
      end
      click_button "Save changes"

      expect(page).to have_content "Changes saved"
      expect(page).to have_selector row_containing_name("Pommes")
    end
  end

  describe "creating a new product" do
    let!(:stock_location) { create(:stock_location, backorderable_default: false) }
    let!(:supplier) { create(:supplier_enterprise) }
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:shipping_category) { create(:shipping_category) }
    let!(:taxon) { create(:taxon) }

    before do
      login_as_admin
      visit spree.admin_products_path
    end

    it "creating a new product" do
      find("a", text: "New Product").click
      expect(page).to have_content "New Product"
      fill_in 'product_name', with: 'Big Bag Of Apples'
      tomselect_select supplier.name, from: 'product[supplier_id]'
      select_tom_select 'Weight (g)', from: 'product_variant_unit_field'
      fill_in 'product_unit_value', with: '100'
      fill_in 'product_price', with: '10.00'
      # TODO dropdowns below are still using select2:
      select taxon.name, from: 'product_primary_taxon_id' # ...instead of tom-select
      select shipping_category.name, from: 'product_shipping_category_id' # ...instead of tom-select
      click_button 'Create'
      expect(URI.parse(current_url).path).to eq spree.admin_products_path
      expect(flash_message).to eq 'Product "Big Bag Of Apples" has been successfully created!'
      expect(page).to have_field "_products_0_name", with: 'Big Bag Of Apples'
    end
  end

  context "creating new variants" do
    let!(:product) { create(:product, variant_unit: 'weight', variant_unit_scale: 1000) }

    before do
      login_as_admin
      visit spree.admin_products_path
    end

    it "hovering over the New variant button displays the text" do
      page.find('button[aria-label="New variant"]', text: "New variant", visible: false)
      find("button.secondary.condensed.naked.icon-plus").hover
      page.find('button[aria-label="New variant"]', text: "New variant", visible: true)
      expect(page).to have_content "New variant"
    end

    shared_examples "creating a new variant (bulk)" do |stock|
      it "handles the #{stock} behaviour" do
        # the product and the default variant is displayed
        expect(page).to have_selector("input[aria-label=Name][value='#{product.name}']",
                                      visible: true, count: 1)
        expect(page).to have_selector("input[aria-label=Name][placeholder='#{product.name}']",
                                      visible: false, count: 1)

        # when a second variant is added, the number of lines increases
        expect {
          find("button.secondary.condensed.naked.icon-plus").click
        }.to change{
          page.all("input[aria-label=Name][placeholder='#{product.name}']", visible: false).count
        }.from(1).to(2)

        # When I fill out variant details and hit update
        within page.all("tr.condensed")[1] do # selects second variant row
          find('input[id$="_sku"]').fill_in with: "345"
          find('input[id$="_display_name"]').fill_in with: "Small bag"
          find('button[id$="unit_to_display"]').click # opens the unit value pop out
          find('input[id$="_unit_value_with_description"]').fill_in with: "0.002"
          find('input[id$="_display_as"]').fill_in with: "2 grams"
          find('button[aria-label="On Hand"]').click
          find('input[id$="_price"]').fill_in with: "11.1"
          if stock == "on_hand"
            find('input[id$="_on_hand"]').fill_in with: "66"
          elsif stock == "on_demand"
            find('input[id$="_on_demand"]').check
          end
        end

        expect(page).to have_content "1 product modified."

        expect {
          click_on "Save changes"
          expect(page).to have_content "Changes saved"
        }.to change {
               Spree::Variant.count
             }.from(1).to(2)

        click_on "Dismiss"
        expect(page).not_to have_content "Changes saved"

        new_variant = Spree::Variant.where(deleted_at: nil).last
        expect(new_variant.sku).to eq "345"
        expect(new_variant.display_name).to eq "Small bag"
        expect(new_variant.unit_value).to eq 2.0
        expect(new_variant.display_as).to eq "2 grams"
        expect(new_variant.unit_presentation).to eq "2 grams"
        expect(new_variant.price).to eq 11.1
        if stock == "on_hand"
          expect(new_variant.on_hand).to eq 66
        elsif stock == "on_demand"
          expect(new_variant.on_demand).to eq true
        end

        within page.all("tr.condensed")[1] do # selects second variant row
          page.find('input[id$="_sku"]').fill_in with: "789"
        end

        accept_confirm do
          click_on "Discard changes" # does not save chages
        end
        expect(page).not_to have_content "Changes saved"
      end
    end

    it_behaves_like "creating a new variant (bulk)", "on_hand"
    it_behaves_like "creating a new variant (bulk)", "on_demand"
  end
end
