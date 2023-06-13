# frozen_string_literal: true

require 'system_helper'

describe 'White label setting' do
  include AuthenticationHelper
  include ShopWorkflow
  include FileHelper
  include UIComponentHelper

  let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let!(:shipping_method) { create(:shipping_method, distributors: [distributor]) }
  let(:product) {
    create(:taxed_product, supplier: create(:supplier_enterprise), price: 10,
                           zone: create(:zone_with_member), tax_rate_amount: 0.1)
  }
  let!(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor],
                                coordinator: create(:distributor_enterprise),
                                variants: [product.variants.first])
  }
  let!(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }
  let(:complete_order) {
    create(:order_with_credit_payment,
           user: nil,
           email: "guest@user.com",
           distributor: distributor,
           order_cycle: order_cycle)
  }

  let(:ofn_navigation) { 'ul.nav-main-menu' }

  shared_examples "hides the OFN navigation for mobile view as well" do
    context "mobile view" do
      around { |example| browse_as_small { example.run } }

      it "hides OFN navigation" do
        find("a.left-off-canvas-toggle").click
        within "aside.left-off-canvas-menu" do
          expect(page).not_to have_selector "a[href='#{main_app.shops_path}']"
          expect(page).not_to have_selector "a[href='#{main_app.map_path}']"
          expect(page).not_to have_selector "a[href='#{main_app.producers_path}']"
          expect(page).not_to have_selector "a[href='#{main_app.groups_path}']"
          expect(page).not_to have_selector "a[href='#{I18n.t('.menu_5_url')}']"
        end
      end
    end
  end

  shared_examples "does not hide the OFN navigation for mobile view as well" do
    context "mobile view" do
      around { |example| browse_as_small { example.run } }

      it "does not hide OFN navigation" do
        find("a.left-off-canvas-toggle").click
        within "aside.left-off-canvas-menu" do
          expect(page).to have_selector "a[href='#{main_app.shops_path}']"
          expect(page).to have_selector "a[href='#{main_app.map_path}']"
          expect(page).to have_selector "a[href='#{main_app.producers_path}']"
          expect(page).to have_selector "a[href='#{main_app.groups_path}']"
          expect(page).to have_selector "a[href='#{I18n.t('.menu_5_url')}']"
        end
      end
    end
  end

  shared_examples "does not hide the OFN navigation" do
    context "for shop path" do
      before do
        visit main_app.enterprise_shop_path(distributor)
      end

      it "does not hide the OFN navigation" do
        expect(page).to have_selector ofn_navigation
      end

      it_behaves_like "does not hide the OFN navigation for mobile view as well"
    end

    context "for cart path" do
      before do
        visit main_app.cart_path
      end

      it "does not hide the OFN navigation" do
        expect(page).to have_selector ofn_navigation
      end

      it_behaves_like "does not hide the OFN navigation for mobile view as well"
    end

    context "for root path" do
      before do
        visit main_app.root_path
      end

      it "does not hide the OFN navigation" do
        expect(page).to have_selector ofn_navigation
      end

      it_behaves_like "does not hide the OFN navigation for mobile view as well"
    end
  end

  context "manage the hide_ofn_navigation preference" do
    context "when the preference is set to true" do
      before do
        distributor.update_attribute(:hide_ofn_navigation, true)
      end

      shared_examples "hides the OFN navigation when needed only" do
        context "for shop path" do
          before do
            visit main_app.enterprise_shop_path(distributor)
          end

          it "hides the OFN navigation" do
            expect(page).to have_no_selector ofn_navigation
          end

          it_behaves_like "hides the OFN navigation for mobile view as well"
        end

        context "for root path" do
          before do
            visit main_app.root_path
          end

          it "does not hide the OFN navigation when visiting root path" do
            expect(page).to have_selector ofn_navigation
          end

          it_behaves_like "does not hide the OFN navigation for mobile view as well"
        end
      end

      context "without order or current distributor" do
        it_behaves_like "hides the OFN navigation when needed only"
      end

      context "when the user has an order ready to checkout" do
        before do
          order.update_attribute(:state, 'cart')
          order.line_items << create(:line_item, variant: product.variants.first)
          set_order(order)
        end

        context "when the split checkout is enabled" do
          it_behaves_like "hides the OFN navigation when needed only"

          context "for cart path" do
            before do
              visit main_app.cart_path
            end

            it "hides the OFN navigation" do
              expect(page).to have_no_selector ofn_navigation
            end

            it_behaves_like "hides the OFN navigation for mobile view as well"
          end

          context "for checkout path" do
            before do
              visit checkout_path
            end

            it "hides the OFN navigation" do
              expect(page).to have_content "Checkout now"
              expect(page).to have_content "Order ready for "
              expect(page).to have_no_selector ofn_navigation
            end

            it_behaves_like "hides the OFN navigation for mobile view as well"
          end
        end
      end

      context "when the user has a complete order" do
        before do
          set_order(complete_order)
        end

        shared_examples "hides the OFN navigation when needed only for the order confirmation" do
          context "for order confirmation path" do
            before do
              visit order_path(complete_order, order_token: complete_order.token)
            end

            it "hides the OFN navigation" do
              expect(page).to have_no_selector ofn_navigation
            end
          end
        end

        context "when the current distributor is the distributor of the order" do
          before do
            allow_any_instance_of(EnterprisesHelper).to receive(:current_distributor).
              and_return(distributor)
          end

          it_behaves_like "hides the OFN navigation when needed only for the order confirmation"
        end

        context "when the user has a current distributor that is not the distributor's order" do
          let!(:another_distributor) { create(:distributor_enterprise) }
          before do
            another_distributor.update_attribute(:hide_ofn_navigation, false)
            allow_any_instance_of(EnterprisesHelper).to receive(:current_distributor).
              and_return(another_distributor)
          end

          it_behaves_like "hides the OFN navigation when needed only for the order confirmation"
        end
      end

      context "when the user has a current distributor" do
        before do
          allow_any_instance_of(EnterprisesHelper).to receive(:current_distributor).
            and_return(distributor)
        end

        it_behaves_like "hides the OFN navigation when needed only"
      end
    end

    context "when the preference is set to false" do
      before do
        distributor.update_attribute(:hide_ofn_navigation, false)
        set_order(order)
        allow_any_instance_of(EnterprisesHelper).to receive(:current_distributor).
          and_return(distributor)
      end

      it_behaves_like "does not hide the OFN navigation"
    end

    context "manage hide_groups_tab preference when distributor belongs to a group" do
      let(:group) { create(:enterprise_group) }

      before do
        distributor.groups << group
      end

      context "when the preference is set to true" do
        before do
          distributor.update_attribute(:hide_groups_tab, true)
        end

        it "hides the groups tab" do
          visit main_app.enterprise_shop_path(distributor)
          expect(page).to have_no_selector "a[href='#groups']"
        end
      end

      context "when the preference is set to false" do
        before do
          distributor.update_attribute(:hide_groups_tab, false)
        end

        it "shows the groups tab" do
          visit main_app.enterprise_shop_path(distributor)
          expect(page).to have_selector "a[href='#groups_panel']"
        end
      end
    end
  end

  context "manage the white_label_logo preference" do
    context "when the distributor has no logo" do
      before do
        distributor.update_attribute(:hide_ofn_navigation, true)
      end

      shared_examples "shows/hide the right logos" do
        it "shows the OFN logo on shop page" do
          expect(page).to have_selector "img[src*='/default_images/ofn-logo.png']"
        end
      end

      context "on shop page" do
        before do
          visit main_app.enterprise_shop_path(distributor)
        end

        it_behaves_like "shows/hide the right logos"
      end

      context "on cart page" do
        before do
          order.update_attribute(:state, 'cart')
          order.line_items << create(:line_item, variant: product.variants.first)
          set_order(order)
          visit main_app.cart_path
        end

        it_behaves_like "shows/hide the right logos"
      end

      context "on checkout page" do
        before do
          order.update_attribute(:state, 'cart')
          order.line_items << create(:line_item, variant: product.variants.first)
          set_order(order)
          visit checkout_path
        end

        it_behaves_like "shows/hide the right logos"
      end

      context "on order confirmation page" do
        before do
          visit order_path(complete_order, order_token: complete_order.token)
        end

        it_behaves_like "shows/hide the right logos"
      end
    end

    context "when the distributor has a logo" do
      before do
        distributor.update_attribute(:hide_ofn_navigation, true)
        distributor.update white_label_logo: white_logo_file
      end

      shared_examples "shows/hide the right logos" do
        it "shows the white label logo on shop page" do
          expect(page).to have_selector "img[src*='/logo-white.png']"
        end
        it "does not show the OFN logo on shop page" do
          expect(page).not_to have_selector "img[src*='/default_images/ofn-logo.png']"
        end
        it "links the logo to the default URL" do
          within ".nav-logo .ofn-logo" do
            expect(page).to have_selector "a[href='/']"
          end
        end
      end

      context "on shop page" do
        before do
          visit main_app.enterprise_shop_path(distributor)
        end

        it_behaves_like "shows/hide the right logos"
      end

      context "on cart page" do
        before do
          order.update_attribute(:state, 'cart')
          order.line_items << create(:line_item, variant: product.variants.first)
          set_order(order)
          visit main_app.cart_path
        end

        it_behaves_like "shows/hide the right logos"
      end

      context "on checkout page" do
        before do
          order.update_attribute(:state, 'cart')
          order.line_items << create(:line_item, variant: product.variants.first)
          set_order(order)
          visit checkout_path
        end

        it_behaves_like "shows/hide the right logos"
      end

      context "on order confirmation page" do
        before do
          visit order_path(complete_order, order_token: complete_order.token)
        end

        it_behaves_like "shows/hide the right logos"
      end

      context "and a link on this logo" do
        before do
          distributor.update_attribute(:white_label_logo_link, "https://www.example.com")
        end

        shared_examples "shows the right link on the logo" do
          it "shows the white label logo link" do
            within ".nav-logo .ofn-logo" do
              expect(page).to_not have_selector "a[href='/']"
              expect(page).to have_selector "a[href*='https://www.example.com']"
            end
          end
        end

        context "on shop page" do
          before do
            visit main_app.enterprise_shop_path(distributor)
          end

          it_behaves_like "shows the right link on the logo"
        end

        context "on cart page" do
          before do
            order.update_attribute(:state, 'cart')
            order.line_items << create(:line_item, variant: product.variants.first)
            set_order(order)
            visit main_app.cart_path
          end

          it_behaves_like "shows the right link on the logo"
        end

        context "on checkout page" do
          before do
            order.update_attribute(:state, 'cart')
            order.line_items << create(:line_item, variant: product.variants.first)
            set_order(order)
            visit checkout_path
          end

          it_behaves_like "shows the right link on the logo"
        end

        context "on order confirmation page" do
          before do
            visit order_path(complete_order, order_token: complete_order.token)
          end

          it_behaves_like "shows the right link on the logo"
        end
      end
    end
  end

  context "manage the custom tab preference" do
    context "when the distributor has a custom tab" do
      let(:custom_tab) { create(:custom_tab) }

      before do
        distributor.update(custom_tab: custom_tab)
        visit main_app.enterprise_shop_path(distributor)
      end

      it "shows the custom tab on shop page" do
        expect(page).to have_selector(".tab-buttons .page", count: 5)
        expect(page).to have_content custom_tab.title
      end

      it "shows the custom tab content when clicking on tab title" do
        click_link custom_tab.title
        expect(page).to have_content custom_tab.content
      end
    end

    context "when the distributor has no custom tab" do
      it "does not show the custom tab on shop page" do
        visit main_app.enterprise_shop_path(distributor)
        expect(page).to have_selector(".tab-buttons .page", count: 4)
      end
    end
  end
end
