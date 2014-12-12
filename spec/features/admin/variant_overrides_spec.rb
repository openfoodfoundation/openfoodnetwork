require 'spec_helper'

feature %q{
  As an Administrator
  With products I can add to order cycles
  I want to override the stock level and price of those products
  Without affecting other hubs that share the same products
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  let!(:hub) { create(:distributor_enterprise) }
  let!(:hub2) { create(:distributor_enterprise) }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:er1) { create(:enterprise_relationship, parent: producer, child: hub,
                     permissions_list: [:add_to_order_cycle]) }

  context "as an enterprise user" do
    let(:user) { create_enterprise_user enterprises: [hub, hub2, producer] }
    before { quick_login_as user }

    describe "selecting a hub" do
      it "displays a list of hub choices" do
        visit '/admin/variant_overrides'
        page.should have_select2 'hub_id', options: ['', hub.name, hub2.name]
      end

      it "displays the hub" do
        visit '/admin/variant_overrides'
        select2_select hub.name, from: 'hub_id'
        click_button 'Go'

        page.should have_selector 'h2', text: hub.name
      end
    end

    context "when a hub is selected" do
      let!(:product) { create(:simple_product, supplier: producer, variant_unit: 'weight', variant_unit_scale: 1) }
      let!(:variant) { create(:variant, product: product, unit_value: 1, price: 1.23, on_hand: 12) }
      let!(:producer2) { create(:supplier_enterprise) }
      let!(:product2) { create(:simple_product, supplier: producer2) }
      let!(:er2) { create(:enterprise_relationship, parent: producer2, child: hub2,
                         permissions_list: [:add_to_order_cycle]) }

      before do
        # Remove 'S' option value
        variant.option_values.first.destroy
      end

      context "with no overrides" do
        before do
          visit '/admin/variant_overrides'
          select2_select hub.name, from: 'hub_id'
          click_button 'Go'
        end

        it "displays the list of products with variants" do
          page.should have_table_row ['PRODUCER', 'PRODUCT', 'PRICE', 'ON HAND']
          page.should have_table_row [producer.name, product.name, '', '']
          page.should have_input "variant-overrides-#{variant.id}-price", placeholder: '1.23'
          page.should have_input "variant-overrides-#{variant.id}-count-on-hand", placeholder: '12'
        end

        it "filters the products to those the hub can add to an order cycle" do
          page.should_not have_content producer2.name
          page.should_not have_content product2.name
        end

        it "creates new overrides" do
          fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
          fill_in "variant-overrides-#{variant.id}-count-on-hand", with: '123'
          page.should have_content "Changes to one override remain unsaved."

          expect do
            click_button 'Save Changes'
            page.should have_content "Changes saved."
          end.to change(VariantOverride, :count).by(1)

          vo = VariantOverride.last
          vo.variant_id.should == variant.id
          vo.hub_id.should == hub.id
          vo.price.should == 777.77
          vo.count_on_hand.should == 123
        end

        it "displays an error when unauthorised to access the page" do
          fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
          fill_in "variant-overrides-#{variant.id}-count-on-hand", with: '123'
          page.should have_content "Changes to one override remain unsaved."

          user.enterprises.clear

          expect do
            click_button 'Save Changes'
            page.should have_content "I couldn't get authorisation to save those changes, so they remain unsaved."
          end.to change(VariantOverride, :count).by(0)
        end

        it "displays an error when unauthorised to update a particular override" do
          fill_in "variant-overrides-#{variant.id}-price", with: '777.77'
          fill_in "variant-overrides-#{variant.id}-count-on-hand", with: '123'
          page.should have_content "Changes to one override remain unsaved."

          EnterpriseRole.where(user_id: user).where('enterprise_id != ?', producer).destroy_all
          er1.destroy
          er2.destroy

          expect do
            click_button 'Save Changes'
            page.should have_content "I couldn't get authorisation to save those changes, so they remain unsaved."
          end.to change(VariantOverride, :count).by(0)
        end
      end

      context "with overrides" do
        let!(:vo) { create(:variant_override, variant: variant, hub: hub, price: 77.77, count_on_hand: 11111) }

        before do
          visit '/admin/variant_overrides'
          select2_select hub.name, from: 'hub_id'
          click_button 'Go'
        end

        it "product values are affected by overrides" do
          page.should have_input "variant-overrides-#{variant.id}-price", with: '77.77', placeholder: '1.23'
          page.should have_input "variant-overrides-#{variant.id}-count-on-hand", with: '11111', placeholder: '12'
        end

        it "updates existing overrides" do
          fill_in "variant-overrides-#{variant.id}-price", with: '22.22'
          fill_in "variant-overrides-#{variant.id}-count-on-hand", with: '8888'
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

        it "deletes overrides when values are cleared" do
          fill_in "variant-overrides-#{variant.id}-price", with: ''
          fill_in "variant-overrides-#{variant.id}-count-on-hand", with: ''
          page.should have_content "Changes to one override remain unsaved."

          expect do
            click_button 'Save Changes'
            page.should have_content "Changes saved."
          end.to change(VariantOverride, :count).by(-1)

          VariantOverride.where(id: vo.id).should be_empty
        end
      end
    end
  end
end
