# frozen_string_literal: true

require 'system_helper'

describe "
  Managing a hub's inventory
  I want to override the stock level and price of products
  Without affecting other hubs that share the same products
" do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  context "as the manager of a hub" do
    let!(:hub) { create(:distributor_enterprise) }
    let!(:hub2) { create(:distributor_enterprise) }
    let!(:producer) { create(:supplier_enterprise) }
    let!(:producer_managed) { create(:supplier_enterprise) }
    let!(:producer_related) { create(:supplier_enterprise) }
    let!(:producer_unrelated) { create(:supplier_enterprise) }
    let!(:er1) {
      create(:enterprise_relationship, parent: producer, child: hub,
                                       permissions_list: [:create_variant_overrides])
    }
    let!(:er2) {
      create(:enterprise_relationship, parent: producer_related, child: hub,
                                       permissions_list: [:create_variant_overrides])
    }
    let(:user) { create(:user, enterprises: [hub, producer_managed]) }

    before { login_as user }

    describe "selecting a hub" do
      let!(:er1) {
        create(:enterprise_relationship, parent: hub2, child: producer_managed,
                                         permissions_list: [:add_to_order_cycle])
      } # This er should not confer ability to create VOs for hub2

      it "displays a list of hub choices (ie. only those managed by the user)" do
        visit spree.admin_dashboard_path
        click_link 'Products'
        click_link 'Inventory'

        expect(page).to have_select2 'hub_id', options: [hub.name] # Selects the hub automatically when only one is available
      end
    end

    context "when inventory_items exist for variants" do
      let!(:product) {
        create(:simple_product, supplier: producer, variant_unit: 'weight', variant_unit_scale: 1)
      }
      let!(:variant) { create(:variant, product: product, unit_value: 1, price: 1.23, on_hand: 12) }
      let!(:inventory_item) { create(:inventory_item, enterprise: hub, variant: variant ) }

      let!(:product_managed) {
        create(:simple_product, supplier: producer_managed, variant_unit: 'weight',
                                variant_unit_scale: 1)
      }
      let!(:variant_managed) {
        create(:variant, product: product_managed, unit_value: 3, price: 3.65, on_hand: 2)
      }
      let!(:inventory_item_managed) {
        create(:inventory_item, enterprise: hub, variant: variant_managed )
      }

      let!(:product_related) { create(:simple_product, supplier: producer_related) }
      let!(:variant_related) {
        create(:variant, product: product_related, unit_value: 2, price: 2.34, on_hand: 23)
      }
      let!(:inventory_item_related) {
        create(:inventory_item, enterprise: hub, variant: variant_related )
      }

      let!(:product_unrelated) { create(:simple_product, supplier: producer_unrelated) }

      before do
        # Remove 'S' option value
        variant.option_values.first.destroy
      end

      context "when a hub is selected" do
        before do
          visit '/admin/inventory'
          select2_select hub.name, from: 'hub_id'
        end

        context "with no overrides" do
          it "displays the list of products with variants" do
            expect(page).to have_table_row ['PRODUCER', 'PRODUCT', 'PRICE', 'ON HAND', 'ON DEMAND?']
            expect(page).to have_table_row [producer.name, product.name, '', '', '']
            expect(page).to have_input "variant-overrides-#{variant.id}-price", placeholder: '1.23'
            expect(page).to have_input "variant-overrides-#{variant.id}-count_on_hand",
                                       placeholder: '12'

            expect(page).to have_table_row [producer_related.name, product_related.name, '', '', '']
            expect(page).to have_input "variant-overrides-#{variant_related.id}-price",
                                       placeholder: '2.34'
            expect(page).to have_input "variant-overrides-#{variant_related.id}-count_on_hand",
                                       placeholder: '23'

            # filters the products to those the hub can override
            expect(page).not_to have_content producer_managed.name
            expect(page).not_to have_content product_managed.name
            expect(page).not_to have_content producer_unrelated.name
            expect(page).not_to have_content product_unrelated.name

            # Filters based on the producer select filter
            expect(page).to have_selector "#v_#{variant.id}"
            expect(page).to have_selector "#v_#{variant_related.id}"
            select2_select producer.name, from: 'producer_filter'
            expect(page).to have_selector "#v_#{variant.id}"
            expect(page).to have_no_selector "#v_#{variant_related.id}"
            select2_select 'All', from: 'producer_filter'

            # Filters based on the quick search box
            expect(page).to have_selector "#v_#{variant.id}"
            expect(page).to have_selector "#v_#{variant_related.id}"
            fill_in 'query', with: product.name
            expect(page).to have_selector "#v_#{variant.id}"
            expect(page).to have_no_selector "#v_#{variant_related.id}"
            fill_in 'query', with: ''

            # Clears the filters
            expect(page).to have_selector "tr#v_#{variant.id}"
            expect(page).to have_selector "tr#v_#{variant_related.id}"
            select2_select producer.name, from: 'producer_filter'
            fill_in 'query', with: product_related.name
            expect(page).to have_no_selector "tr#v_#{variant.id}"
            expect(page).to have_no_selector "tr#v_#{variant_related.id}"
            click_button 'Clear All'
            expect(page).to have_selector "tr#v_#{variant.id}"
            expect(page).to have_selector "tr#v_#{variant_related.id}"

            # Show/Hide products
            toggle_columns "Hide"
            expect(page).to have_selector "tr#v_#{variant.id}"
            expect(page).to have_selector "tr#v_#{variant_related.id}"
            within "tr#v_#{variant.id}" do click_button 'Hide' end
            expect(page).to have_no_selector "tr#v_#{variant.id}"
            expect(page).to have_selector "tr#v_#{variant_related.id}"
            first("div#views-dropdown").click
            first("div#views-dropdown div.menu div.menu_item", text: "Hidden Products").click
            expect(page).to have_selector "tr#v_#{variant.id}"
            expect(page).to have_no_selector "tr#v_#{variant_related.id}"
            within "tr#v_#{variant.id}" do click_button 'Add' end
            expect(page).to have_no_selector "tr#v_#{variant.id}"
            expect(page).to have_no_selector "tr#v_#{variant_related.id}"
            first("div#views-dropdown").click
            first("div#views-dropdown div.menu div.menu_item", text: "Inventory Products").click
            expect(page).to have_selector "tr#v_#{variant.id}"
            expect(page).to have_selector "tr#v_#{variant_related.id}"
          end

          it "creates new overrides" do
            toggle_columns "SKU"

            fill_in "variant-overrides-#{variant.id}-sku", with: 'NEWSKU'
            fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
            select_on_demand variant, :no
            fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '123'
            expect(page).to have_content "Changes to one override remain unsaved."

            expect do
              click_button 'Save Changes'
              expect(page).to have_content "Changes saved."
            end.to change(VariantOverride, :count).by(1)

            vo = VariantOverride.last
            expect(vo.variant_id).to eq(variant.id)
            expect(vo.hub_id).to eq(hub.id)
            expect(vo.sku).to eq("NEWSKU")
            expect(vo.price).to eq(777.77)
            expect(vo.on_demand).to eq(false)
            expect(vo.count_on_hand).to eq(123)
          end

          describe "creating and then updating the new override" do
            it "updates the same override instead of creating a duplicate" do
              # When I create a new override
              fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
              select_on_demand variant, :no
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '123'
              expect(page).to have_content "Changes to one override remain unsaved."

              expect do
                click_button 'Save Changes'
                expect(page).to have_content "Changes saved."
              end.to change(VariantOverride, :count).by(1)

              # And I update its settings without reloading the page
              fill_in "variant-overrides-#{variant.id}-price", with: '111.11'
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '111'
              expect(page).to have_content "Changes to one override remain unsaved."

              # Then I shouldn't see a new override
              expect do
                click_button 'Save Changes'
                expect(page).to have_content "Changes saved."
              end.to change(VariantOverride, :count).by(0)

              # And the override should be updated
              vo = VariantOverride.last
              expect(vo.variant_id).to eq(variant.id)
              expect(vo.hub_id).to eq(hub.id)
              expect(vo.price).to eq(111.11)
              expect(vo.on_demand).to eq(false)
              expect(vo.count_on_hand).to eq(111)
            end
          end

          it "displays an error when unauthorised to access the page" do
            fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
            fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '123'
            expect(page).to have_content "Changes to one override remain unsaved."

            # Set a user without suficient permissions
            allow_any_instance_of(Spree::Admin::BaseController).to receive(:current_spree_user).and_return(build(:user))

            expect do
              click_button 'Save Changes'

              # We need to wait_until because the save action is not fast enough for the have_content matcher
              wait_until { page.find("#status-message").text != "Saving..." }
              expect(page).to have_content "I couldn't get authorisation to save those changes, so they remain unsaved."
            end.to change(VariantOverride, :count).by(0)
          end

          it "displays an error when unauthorised to update a particular override" do
            fill_in "variant-overrides-#{variant_related.id}-price", with: '777.77'
            fill_in "variant-overrides-#{variant_related.id}-count_on_hand", with: '123'
            expect(page).to have_content "Changes to one override remain unsaved."

            er2.destroy

            expect do
              click_button 'Save Changes'
              expect(page).to have_content "I couldn't get authorisation to save those changes, so they remain unsaved."
            end.to change(VariantOverride, :count).by(0)
          end
        end

        context "with overrides" do
          let!(:vo) {
            create(:variant_override, :on_demand, variant: variant, hub: hub, price: 77.77,
                                                  default_stock: 1000, resettable: true, tag_list: ["tag1", "tag2", "tag3"])
          }
          let!(:vo_no_auth) {
            create(:variant_override, variant: variant, hub: hub2, price: 1, count_on_hand: 2)
          }
          let!(:product2) {
            create(:simple_product, supplier: producer, variant_unit: 'weight',
                                    variant_unit_scale: 1)
          }
          let!(:variant2) {
            create(:variant, product: product2, unit_value: 8, price: 1.00, on_hand: 12)
          }
          let!(:inventory_item2) { create(:inventory_item, enterprise: hub, variant: variant2) }
          let!(:vo_no_reset) {
            create(:variant_override, variant: variant2, hub: hub, price: 3.99, count_on_hand: 40,
                                      default_stock: 100, resettable: false)
          }
          let!(:variant3) {
            create(:variant, product: product, unit_value: 2, price: 5.00, on_hand: 6)
          }
          let!(:vo3) {
            create(:variant_override, variant: variant3, hub: hub, price: 6, count_on_hand: 7, sku: "SOMESKU",
                                      default_stock: 100, resettable: false)
          }
          let!(:inventory_item3) { create(:inventory_item, enterprise: hub, variant: variant3) }

          before do
            visit '/admin/inventory'
            select2_select hub.name, from: 'hub_id'
          end

          it "product values are affected by overrides" do
            expect(page).to have_input "variant-overrides-#{variant.id}-price", with: '77.77',
                                                                                placeholder: '1.23'
            expect(page).to have_input "variant-overrides-#{variant.id}-count_on_hand", with: "",
                                                                                        placeholder: 'On demand'
            expect(page).to have_select "variant-overrides-#{variant.id}-on_demand",
                                        selected: 'Yes'

            expect(page).to have_input "variant-overrides-#{variant2.id}-count_on_hand",
                                       with: "40", placeholder: ""
          end

          it "updates existing overrides" do
            fill_in "variant-overrides-#{variant.id}-price", with: '22.22'
            select_on_demand variant, :no
            fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '8888'
            expect(page).to have_content "Changes to one override remain unsaved."

            expect do
              click_button 'Save Changes'
              expect(page).to have_content "Changes saved."
            end.to change(VariantOverride, :count).by(0)

            vo.reload
            expect(vo.variant_id).to eq(variant.id)
            expect(vo.hub_id).to eq(hub.id)
            expect(vo.price).to eq(22.22)
            expect(vo.on_demand).to eq(false)
            expect(vo.count_on_hand).to eq(8888)
          end

          it "updates on_demand settings" do
            select_on_demand variant, :no
            click_button 'Save Changes'
            expect(page).to have_content 'Changes saved.'

            vo.reload
            expect(vo.on_demand).to eq(false)

            select_on_demand variant, :yes
            click_button 'Save Changes'
            expect(page).to have_content 'Changes saved.'

            vo.reload
            expect(vo.on_demand).to eq(true)

            select_on_demand variant, :use_producer_settings
            click_button 'Save Changes'
            expect(page).to have_content 'Changes saved.'

            vo.reload
            expect(vo.on_demand).to be_nil
          end

          # Any new fields added to the VO model need to be added to this test
          it "deletes overrides when values are cleared" do
            toggle_columns "Enable Stock Reset?", "Tags"

            # Clearing values by 'inheriting'
            toggle_columns "Inherit?"
            check "variant-overrides-#{variant3.id}-inherit"
            # Hide the Inherit column again. When that column is visible, the
            # size of the Tags column is too short and tags can't be removed.
            # This is a bug and the next line can be removed once it is fixed:
            # https://github.com/openfoodfoundation/openfoodnetwork/issues/3310
            toggle_columns "Inherit?"

            # Clearing values manually
            fill_in "variant-overrides-#{variant.id}-price", with: ''
            select_on_demand variant, :use_producer_settings
            fill_in "variant-overrides-#{variant.id}-default_stock", with: ''
            within "tr#v_#{variant.id}" do
              vo.tag_list.each do |tag|
                within "li.tag-item", text: "#{tag} ✖" do
                  find("a.remove-button").click
                end
              end
            end
            page.uncheck "variant-overrides-#{variant.id}-resettable"
            expect(page).to have_content "Changes to 2 overrides remain unsaved."

            expect do
              click_button 'Save Changes'
              expect(page).to have_content "Changes saved."
            end.to change(VariantOverride, :count).by(-2)

            expect(VariantOverride.where(id: vo.id)).to be_empty
            expect(VariantOverride.where(id: vo3.id)).to be_empty
          end

          it "resets stock to defaults" do
            first("div#bulk-actions-dropdown").click
            first("div#bulk-actions-dropdown div.menu div.menu_item",
                  text: "Reset Stock Levels To Defaults").click
            expect(page).to have_content 'Stocks reset to defaults.'
            vo.reload
            expect(page).to have_input "variant-overrides-#{variant.id}-count_on_hand",
                                       with: "1000", placeholder: ""
            expect(vo.count_on_hand).to eq(1000)
          end

          it "doesn't reset stock levels if the behaviour is disabled" do
            first("div#bulk-actions-dropdown").click
            first("div#bulk-actions-dropdown div.menu div.menu_item",
                  text: "Reset Stock Levels To Defaults").click
            vo_no_reset.reload
            expect(page).to have_input "variant-overrides-#{variant2.id}-count_on_hand",
                                       with: "40", placeholder: ""
            expect(vo_no_reset.count_on_hand).to eq(40)
          end

          it "prompts to save changes before reset if any are pending" do
            fill_in "variant-overrides-#{variant.id}-price", with: '200'
            first("div#bulk-actions-dropdown").click
            first("div#bulk-actions-dropdown div.menu div.menu_item",
                  text: "Reset Stock Levels To Defaults").click
            expect(page).to have_content "Save changes first"
          end

          describe "ensuring that on demand and count on hand settings are compatible" do
            it "clears count on hand when not limited stock" do
              # It clears count_on_hand when selecting true on_demand.
              select_on_demand variant, :no
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: "200"
              select_on_demand variant, :yes
              expect(page).to have_input "variant-overrides-#{variant.id}-count_on_hand", with: ""

              # It clears count_on_hand when selecting nil on_demand.
              select_on_demand variant, :no
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: "200"
              select_on_demand variant, :use_producer_settings
              expect(page).to have_input "variant-overrides-#{variant.id}-count_on_hand", with: ""

              # It saves the changes.
              click_button 'Save Changes'
              expect(page).to have_content 'Changes saved.'
              vo.reload
              expect(vo.count_on_hand).to be_nil
              expect(vo.on_demand).to be_nil
            end

            it "provides explanation when attempting to save variant override with incompatible stock settings" do
              # Successfully change stock settings.
              select_on_demand variant, :no
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: "1111"
              click_button 'Save Changes'
              expect(page).to have_content 'Changes saved.'

              # Make stock settings incompatible.
              select_on_demand variant, :no
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: ""

              # It does not save the changes.
              click_button 'Save Changes'
              expect(page).to have_content 'must be specified because forcing limited stock'
              expect(page).to have_no_content 'Changes saved.'

              vo.reload
              expect(vo.count_on_hand).to eq(1111)
              expect(vo.on_demand).to eq(false)
            end
          end
        end
      end
    end

    describe "when manually placing an order" do
      let!(:order_cycle) { create(:order_cycle_with_overrides, name: "Overidden") }
      let(:distributor) { order_cycle.distributors.first }
      let(:product) { order_cycle.products.first }

      before do
        login_as_admin_and_visit spree.new_admin_order_path
        select2_select distributor.name, from: 'order_distributor_id'
        select2_select order_cycle.name, from: 'order_order_cycle_id'
        click_button 'Next'
        click_link "Order Details"
      end

      # Reproducing a bug, issue #1446
      it "shows the overridden price" do
        select2_select product.name, from: 'add_variant_id', search: true
        find('button.add_variant').click
        expect(page).to have_selector("table.index tbody tr") # Wait for JS
        expect(page).to have_content(product.variants.first.variant_overrides.first.price)
      end
    end

    describe "when inventory_items do not exist for variants" do
      let!(:product) {
        create(:simple_product, supplier: producer, variant_unit: 'weight', variant_unit_scale: 1)
      }
      let!(:variant1) {
        create(:variant, product: product, unit_value: 1, price: 1.23, on_hand: 12)
      }
      let!(:variant2) { create(:variant, product: product, unit_value: 2, price: 4.56, on_hand: 3) }

      context "when a hub is selected" do
        before do
          visit '/admin/inventory'
          select2_select hub.name, from: 'hub_id'
        end

        it "alerts the user to the presence of new products, and allows them to be added or hidden" do
          expect(page).to have_no_selector "table#variant-overrides tr#v_#{variant1.id}"
          expect(page).to have_no_selector "table#variant-overrides tr#v_#{variant2.id}"

          expect(page).to have_selector '.alert-row span.message',
                                        text: "There are 1 new products available to add to your inventory."
          click_button "Review Now"

          expect(page).to have_table_row ['PRODUCER', 'PRODUCT', 'VARIANT', 'ADD', 'HIDE']
          expect(page).to have_selector "table#new-products tr#v_#{variant1.id}"
          expect(page).to have_selector "table#new-products tr#v_#{variant2.id}"
          within "table#new-products tr#v_#{variant1.id}" do click_button 'Add' end
          within "table#new-products tr#v_#{variant2.id}" do click_button 'Hide' end
          expect(page).to have_no_selector "table#new-products tr#v_#{variant1.id}"
          expect(page).to have_no_selector "table#new-products tr#v_#{variant2.id}"
          click_button "Back to my inventory"

          expect(page).to have_selector "table#variant-overrides tr#v_#{variant1.id}"
          expect(page).to have_no_selector "table#variant-overrides tr#v_#{variant2.id}"

          first("div#views-dropdown").click
          first("div#views-dropdown div.menu div.menu_item", text: "Hidden Products").click

          expect(page).to have_no_selector "table#hidden-products tr#v_#{variant1.id}"
          expect(page).to have_selector "table#hidden-products tr#v_#{variant2.id}"
        end
      end
    end
  end

  context "as the manager of a farm shop" do
    it "shows more than 100 products in my inventory" do
      supplier = create(:supplier_enterprise, sells: "own")
      inventory_items = (1..101).map do
        product = create(:simple_product, supplier: supplier)
        InventoryItem.create!(
          enterprise: supplier,
          variant: product.variants.first
        )
      end
      first_variant = inventory_items.first.variant
      last_variant = inventory_items.last.variant
      first_variant.product.update!(name: "A First Product")
      last_variant.product.update!(name: "Z Last Product")
      login_as supplier.users.first
      visit admin_inventory_path

      expect(page).to have_text first_variant.name
      expect(page).to have_selector "tr.product", count: 10
      expect(page).to have_button "Show more"
      expect(page).to have_button "Show all (91  More)"

      click_button "Show all (91  More)"
      expect(page).to have_selector "tr.product", count: 101
      expect(page).to have_text last_variant.name
    end
  end

  def select_on_demand(variant, value_sym)
    option_label = I18n.t(value_sym, scope: "js.variant_overrides.on_demand")
    select option_label, from: "variant-overrides-#{variant.id}-on_demand"
  end
end
