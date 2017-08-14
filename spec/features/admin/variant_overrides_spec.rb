require 'spec_helper'

feature %q{
  As an Administrator
  With products I can add to my hub's inventory
  I want to override the stock level and price of those products
  Without affecting other hubs that share the same products
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:hub) { create(:distributor_enterprise) }
  let!(:hub2) { create(:distributor_enterprise) }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:producer_managed) { create(:supplier_enterprise) }
  let!(:producer_related) { create(:supplier_enterprise) }
  let!(:producer_unrelated) { create(:supplier_enterprise) }
  let!(:er1) { create(:enterprise_relationship, parent: producer, child: hub,
                      permissions_list: [:create_variant_overrides]) }
  let!(:er2) { create(:enterprise_relationship, parent: producer_related, child: hub,
                      permissions_list: [:create_variant_overrides]) }

  context "as an enterprise user" do
    let(:user) { create_enterprise_user enterprises: [hub, producer_managed] }
    before { quick_login_as user }

    describe "selecting a hub" do
      let!(:er1) { create(:enterprise_relationship, parent: hub2, child: producer_managed,
                          permissions_list: [:add_to_order_cycle]) } # This er should not confer ability to create VOs for hub2

      it "displays a list of hub choices (ie. only those managed by the user)" do
        visit spree.admin_path
        click_link 'Products'
        click_link 'Inventory'

        page.should have_select2 'hub_id', options: [hub.name] # Selects the hub automatically when only one is available
      end
    end

    context "when inventory_items exist for variants" do
      let!(:product) { create(:simple_product, supplier: producer, variant_unit: 'weight', variant_unit_scale: 1) }
      let!(:variant) { create(:variant, product: product, unit_value: 1, price: 1.23, on_hand: 12) }
      let!(:inventory_item) { create(:inventory_item, enterprise: hub, variant: variant ) }

      let!(:product_managed) { create(:simple_product, supplier: producer_managed, variant_unit: 'weight', variant_unit_scale: 1) }
      let!(:variant_managed) { create(:variant, product: product_managed, unit_value: 3, price: 3.65, on_hand: 2) }
      let!(:inventory_item_managed) { create(:inventory_item, enterprise: hub, variant: variant_managed ) }

      let!(:product_related) { create(:simple_product, supplier: producer_related) }
      let!(:variant_related) { create(:variant, product: product_related, unit_value: 2, price: 2.34, on_hand: 23) }
      let!(:inventory_item_related) { create(:inventory_item, enterprise: hub, variant: variant_related ) }

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
            page.should have_table_row ['PRODUCER', 'PRODUCT', 'PRICE', 'ON HAND']
            page.should have_table_row [producer.name, product.name, '', '']
            page.should have_input "variant-overrides-#{variant.id}-price", placeholder: '1.23'
            page.should have_input "variant-overrides-#{variant.id}-count_on_hand", placeholder: '12'

            page.should have_table_row [producer_related.name, product_related.name, '', '']
            page.should have_input "variant-overrides-#{variant_related.id}-price", placeholder: '2.34'
            page.should have_input "variant-overrides-#{variant_related.id}-count_on_hand", placeholder: '23'

            # filters the products to those the hub can override
            page.should_not have_content producer_managed.name
            page.should_not have_content product_managed.name
            page.should_not have_content producer_unrelated.name
            page.should_not have_content product_unrelated.name

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
            first("div#columns-dropdown", :text => "COLUMNS").click
            first("div#columns-dropdown div.menu div.menu_item", text: "Hide").click
            first("div#columns-dropdown", :text => "COLUMNS").click
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
            first("div#columns-dropdown", :text => "COLUMNS").click
            first("div#columns-dropdown div.menu div.menu_item", text: "SKU").click
            first("div#columns-dropdown div.menu div.menu_item", text: "On Demand").click
            first("div#columns-dropdown", :text => "COLUMNS").click

            fill_in "variant-overrides-#{variant.id}-sku", with: 'NEWSKU'
            fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
            fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '123'
            check "variant-overrides-#{variant.id}-on_demand"
            page.should have_content "Changes to one override remain unsaved."

            expect do
              click_button 'Save Changes'
              page.should have_content "Changes saved."
            end.to change(VariantOverride, :count).by(1)

            vo = VariantOverride.last
            vo.variant_id.should == variant.id
            vo.hub_id.should == hub.id
            vo.sku.should == "NEWSKU"
            vo.price.should == 777.77
            vo.count_on_hand.should == 123
            vo.on_demand.should == true
          end

          describe "creating and then updating the new override" do
            it "updates the same override instead of creating a duplicate" do
              # When I create a new override
              fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '123'
              page.should have_content "Changes to one override remain unsaved."

              expect do
                click_button 'Save Changes'
                page.should have_content "Changes saved."
              end.to change(VariantOverride, :count).by(1)

              # And I update its settings without reloading the page
              fill_in "variant-overrides-#{variant.id}-price", with: '111.11'
              fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '111'
              page.should have_content "Changes to one override remain unsaved."

              # Then I shouldn't see a new override
              expect do
                click_button 'Save Changes'
                page.should have_content "Changes saved."
              end.to change(VariantOverride, :count).by(0)

              # And the override should be updated
              vo = VariantOverride.last
              vo.variant_id.should == variant.id
              vo.hub_id.should == hub.id
              vo.price.should == 111.11
              vo.count_on_hand.should == 111
            end
          end

          it "displays an error when unauthorised to access the page" do
            fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
            fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '123'
            page.should have_content "Changes to one override remain unsaved."

            user.enterprises.clear

            expect do
              click_button 'Save Changes'
              page.should have_content "I couldn't get authorisation to save those changes, so they remain unsaved."
            end.to change(VariantOverride, :count).by(0)
          end

          it "displays an error when unauthorised to update a particular override" do
            fill_in "variant-overrides-#{variant_related.id}-price", with: '777.77'
            fill_in "variant-overrides-#{variant_related.id}-count_on_hand", with: '123'
            page.should have_content "Changes to one override remain unsaved."

            er2.destroy

            expect do
              click_button 'Save Changes'
              page.should have_content "I couldn't get authorisation to save those changes, so they remain unsaved."
            end.to change(VariantOverride, :count).by(0)
          end
        end

        context "with overrides" do
          let!(:vo) { create(:variant_override, variant: variant, hub: hub, price: 77.77, count_on_hand: 11111, default_stock: 1000, resettable: true, tag_list: ["tag1","tag2","tag3"]) }
          let!(:vo_no_auth) { create(:variant_override, variant: variant, hub: hub2, price: 1, count_on_hand: 2) }
          let!(:product2) { create(:simple_product, supplier: producer, variant_unit: 'weight', variant_unit_scale: 1) }
          let!(:variant2) { create(:variant, product: product2, unit_value: 8, price: 1.00, on_hand: 12) }
          let!(:inventory_item2) { create(:inventory_item, enterprise: hub, variant: variant2) }
          let!(:vo_no_reset) { create(:variant_override, variant: variant2, hub: hub, price: 3.99, count_on_hand: 40, default_stock: 100, resettable: false) }
          let!(:variant3) { create(:variant, product: product, unit_value: 2, price: 5.00, on_hand: 6) }
          let!(:vo3) { create(:variant_override, variant: variant3, hub: hub, price: 6, count_on_hand: 7, sku: "SOMESKU", default_stock: 100, resettable: false) }
          let!(:inventory_item3) { create(:inventory_item, enterprise: hub, variant: variant3) }

          before do
            visit '/admin/inventory'
            select2_select hub.name, from: 'hub_id'
          end

          it "product values are affected by overrides" do
            page.should have_input "variant-overrides-#{variant.id}-price", with: '77.77', placeholder: '1.23'
            page.should have_input "variant-overrides-#{variant.id}-count_on_hand", with: '11111', placeholder: '12'
          end

          it "updates existing overrides" do
            fill_in "variant-overrides-#{variant.id}-price", with: '22.22'
            fill_in "variant-overrides-#{variant.id}-count_on_hand", with: '8888'
            page.should have_content "Changes to one override remain unsaved."

            expect do
              click_button 'Save Changes'
              page.should have_content "Changes saved."
            end.to change(VariantOverride, :count).by(0)

            vo.reload
            vo.variant_id.should == variant.id
            vo.hub_id.should == hub.id
            vo.price.should == 22.22
            vo.count_on_hand.should == 8888
          end

          # Any new fields added to the VO model need to be added to this test
          it "deletes overrides when values are cleared" do
            first("div#columns-dropdown", :text => "COLUMNS").click
            first("div#columns-dropdown div.menu div.menu_item", text: "On Demand").click
            first("div#columns-dropdown div.menu div.menu_item", text: "Enable Stock Reset?").click
            first("div#columns-dropdown div.menu div.menu_item", text: "Tags").click
            first("div#columns-dropdown", :text => "COLUMNS").click

            # Clearing values by 'inheriting'
            first("div#columns-dropdown", :text => "COLUMNS").click
            first("div#columns-dropdown div.menu div.menu_item", text: "Inherit?").click
            first("div#columns-dropdown", :text => "COLUMNS").click
            check "variant-overrides-#{variant3.id}-inherit"

            # Clearing values manually
            fill_in "variant-overrides-#{variant.id}-price", with: ''
            fill_in "variant-overrides-#{variant.id}-count_on_hand", with: ''
            fill_in "variant-overrides-#{variant.id}-default_stock", with: ''
            within "tr#v_#{variant.id}" do
              vo.tag_list.each do |tag|
                within "li.tag-item", text: "#{tag} ✖" do
                  find("a.remove-button").trigger('click')
                end
              end
            end
            page.uncheck "variant-overrides-#{variant.id}-resettable"
            page.should have_content "Changes to 2 overrides remain unsaved."

            expect do
              click_button 'Save Changes'
              page.should have_content "Changes saved."
            end.to change(VariantOverride, :count).by(-2)

            VariantOverride.where(id: vo.id).should be_empty
            VariantOverride.where(id: vo3.id).should be_empty
          end

          it "resets stock to defaults" do
            first("div#bulk-actions-dropdown").click
            first("div#bulk-actions-dropdown div.menu div.menu_item", text: "Reset Stock Levels To Defaults").click
            page.should have_content 'Stocks reset to defaults.'
            vo.reload
            page.should have_input "variant-overrides-#{variant.id}-count_on_hand", with: '1000', placeholder: '12'
            vo.count_on_hand.should == 1000
          end

          it "doesn't reset stock levels if the behaviour is disabled" do
            first("div#bulk-actions-dropdown").click
            first("div#bulk-actions-dropdown div.menu div.menu_item", text: "Reset Stock Levels To Defaults").click
            vo_no_reset.reload
            page.should have_input "variant-overrides-#{variant2.id}-count_on_hand", with: '40', placeholder: '12'
            vo_no_reset.count_on_hand.should == 40
          end

          it "prompts to save changes before reset if any are pending" do
            fill_in "variant-overrides-#{variant.id}-price", with: '200'
            first("div#bulk-actions-dropdown").click
            first("div#bulk-actions-dropdown div.menu div.menu_item", text: "Reset Stock Levels To Defaults").click
            page.should have_content "Save changes first"
          end
        end
      end

    end

    describe "when manually placing an order" do
      let!(:order_cycle) { create(:order_cycle_with_overrides, name: "Overidden") }
      let(:distributor) { order_cycle.distributors.first }
      let(:product) { order_cycle.products.first }

      before do
        login_to_admin_section

        visit 'admin/orders/new'
        select2_select distributor.name, from: 'order_distributor_id'
        select2_select order_cycle.name, from: 'order_order_cycle_id'
        click_button 'Next'
      end

      # Reproducing a bug, issue #1446
      it "shows the overridden price" do
        targetted_select2_search product.name, from: '#add_variant_id', dropdown_css: '.select2-drop'
        click_link 'Add'
        expect(page).to have_selector("table.index tbody[data-hook='admin_order_form_line_items'] tr") # Wait for JS
        expect(page).to have_content(product.variants.first.variant_overrides.first.price)
      end
    end

    describe "when inventory_items do not exist for variants" do
      let!(:product) { create(:simple_product, supplier: producer, variant_unit: 'weight', variant_unit_scale: 1) }
      let!(:variant1) { create(:variant, product: product, unit_value: 1, price: 1.23, on_hand: 12) }
      let!(:variant2) { create(:variant, product: product, unit_value: 2, price: 4.56, on_hand: 3) }

      context "when a hub is selected" do
        before do
          visit '/admin/inventory'
          select2_select hub.name, from: 'hub_id'
        end

        it "alerts the user to the presence of new products, and allows them to be added or hidden", retry: 3 do
          expect(page).to have_no_selector "table#variant-overrides tr#v_#{variant1.id}"
          expect(page).to have_no_selector "table#variant-overrides tr#v_#{variant2.id}"

          expect(page).to have_selector '.alert-row span.message', text: "There are 1 new products available to add to your inventory."
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
end
