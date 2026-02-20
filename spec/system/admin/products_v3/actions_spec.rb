# frozen_string_literal: true

require "system_helper"

RSpec.describe 'As an enterprise user, I can manage my products' do
  include AdminHelper
  include WebHelper
  include AuthenticationHelper
  include FileHelper

  let(:producer) { create(:supplier_enterprise) }
  let(:user) { create(:user, enterprises: [producer]) }

  before do
    login_as user
  end

  let(:producer_search_selector) { 'input[placeholder="Select producer"]' }
  let(:categories_search_selector) { 'input[placeholder="Select category"]' }
  let(:tax_categories_search_selector) { 'input[placeholder="Search for tax categories"]' }

  describe "with no products" do
    before { visit admin_products_url }
    it "can see the new product page" do
      expect(page).to have_content "Bulk Edit Products"
      expect(page).to have_text "No products found"
      # displays buttons to add products with the correct links
      expect(page).to have_link(class: "button", text: "New Product", href: "/admin/products/new")
      expect(page).to have_link(class: "button", text: "Import multiple products",
                                href: admin_product_import_path)
    end
  end

  describe "column selector" do
    let!(:product) { create(:simple_product) }

    context "with one producer only" do
      before do
        visit admin_products_url
      end

      it "hides column and remembers saved preference" do
        # Name shows by default
        expect(page).to have_checked_field "Name"
        expect(page).to have_selector "th", text: "Name"
        expect_other_columns_visible

        # Producer is hidden by if only one producer is present
        expect(page).to have_unchecked_field "Producer"
        expect(page).not_to have_selector "th", text: "Producer"

        # Show Producer column
        ofn_drop_down("Columns").click
        within ofn_drop_down("Columns") do
          check "Producer"
        end

        # Preference saved
        save_preferences
        expect(page).to have_selector "th", text: "Producer"

        # Name is hidden
        ofn_drop_down("Columns").click
        within ofn_drop_down("Columns") do
          uncheck "Name"
        end
        expect(page).not_to have_selector "th", text: "Name"
        expect_other_columns_visible

        # Preference saved
        save_preferences

        # Preference remembered
        ofn_drop_down("Columns").click
        within ofn_drop_down("Columns") do
          expect(page).to have_unchecked_field "Name"
        end
        expect(page).not_to have_selector "th", text: "Name"
        expect_other_columns_visible
      end

      def expect_other_columns_visible
        expect(page).to have_selector "th", text: "Price"
        expect(page).to have_selector "th", text: "On Hand"
      end

      def save_preferences
        # Preference saved
        click_on "Save as default"
        expect(page).to have_content "Column preferences saved"
        refresh
      end
    end

    context "with multiple producers" do
      let!(:producer2) { create(:supplier_enterprise, owner: user) }

      before { visit admin_products_url }

      it "has selected producer column by default" do
        # Producer shows by default
        expect(page).to have_checked_field "Producer"
        expect(page).to have_selector "th", text: "Producer"
      end
    end
  end

  describe "columns"

  describe "Changing producers, category and tax category" do
    let!(:variant_a1) {
      product_a.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "APL-01", price: 5.25, on_hand: 5,
                  on_demand: false, variant_unit: "weight", variant_unit_scale: 1
      } # Grams
    }
    let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }

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

  describe "actions menu" do
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
        close_action_menu

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
          close_action_menu

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
      end

      it "shows error message when cloning invalid record" do
        # The cloned product will be invalid
        product_a.update_columns(name: "L" * 254)

        # The page has not been reloaded so the product's name is still "Apples"
        click_product_clone "Apples"

        expect(page).to have_content "Product Name is too long (maximum is 255 characters)"

        within "table.products" do
          # Products does not include the cloned product.
          expect(all_input_values).not_to match /COPY OF #{'L' * 254}/
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

            within modal_selector do
              click_button "Keep product"
            end

            expect(page).not_to have_content "Delete Product"
            expect(page).to have_selector(product_selector)

            # Keep Variant
            within variant_selector do
              page.find(".vertical-ellipsis-menu").click
              page.find(delete_option_selector).click
            end
            within modal_selector do
              click_button "Keep variant"
            end

            expect(page).not_to have_content("Delete Variant")
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

            within modal_selector do
              click_button "Delete variant"
            end

            expect(page).not_to have_content("Delete variant")
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
            within modal_selector do
              click_button "Delete product"
            end
            expect(page).not_to have_content("Delete product")
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

            within modal_selector do
              click_button "Delete variant"
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
            within modal_selector do
              click_button "Delete product"
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

              within modal_selector do
                click_button "Delete variant"
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

    describe "Preview" do
      let(:product) { create(:product, name: "Apples") }
      let!(:variant) { create(:variant, product:) }

      it "show product preview modal" do
        visit admin_products_url

        within row_containing_name("Apples") do
          open_action_menu
          click_link "Preview"
        end

        expect(page).to have_content("Product preview")

        within "#product-preview-modal" do
          # Shop tab
          expect(page).to have_selector("h3", text: "Apples")
          add_buttons = page.all(".add-variant")
          expect(add_buttons.length).to eql(2)

          # Product Details tab
          find("a", text: "Product details").click # click_link doesn't work
          expect(page).to have_selector("h3", text: "Apples")
          expect(page).to have_selector(".product-img")

          # Closing the modal
          click_button "Close"
        end

        expect(page).not_to have_content("Product preview")
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

      within row_containing_placeholder(product_supplied.name) do
        expect(page).to have_select(
          '_products_0_variants_attributes_0_supplier_id',
          options: [
            'Select producer',
            supplier_managed1.name, supplier_managed2.name, supplier_permitted.name
          ], selected: supplier_managed1.name
        )
      end

      within row_containing_placeholder(product_supplied_permitted.name) do
        expect(page).to have_select(
          '_products_1_variants_attributes_0_supplier_id',
          options: [
            'Select producer',
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

  def open_action_menu
    page.find(".vertical-ellipsis-menu").click
  end

  def close_action_menu
    page.find("div#content").click
  end
end
