# frozen_string_literal: true

require 'system_helper'

describe 'White label setting' do
  include AuthenticationHelper
  include ShopWorkflow

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

  let(:ofn_navigation) { 'ul.nav-main-menu' }

  shared_examples "does not hide the OFN navigation" do
    it "does not hide the OFN navigation when visiting the shop" do
      visit main_app.enterprise_shop_path(distributor)
      expect(page).to have_selector ofn_navigation
    end

    it "does not hide the OFN navigation when visiting root path" do
      visit main_app.root_path
      expect(page).to have_selector ofn_navigation
    end

    it "does not hide the OFN navigation when visiting cart path" do
      visit main_app.cart_path
      expect(page).to have_selector ofn_navigation
    end
  end

  context "when the white label feature is activated" do
    before do
      Flipper.enable(:white_label)
    end

    context "manage the hide_ofn_navigation preference" do
      context "when the preference is set to true" do
        before do
          distributor.update_attribute(:hide_ofn_navigation, true)
        end

        shared_examples "hides the OFN navigation when needed only" do
          it "hides the OFN navigation when visiting the shop" do
            visit main_app.enterprise_shop_path(distributor)
            expect(page).to have_no_selector ofn_navigation
          end

          it "does not hide the OFN navigation when visiting root path" do
            visit main_app.root_path
            expect(page).to have_selector ofn_navigation
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

          shared_examples "hides the OFN navigation when needed only for the checkout" do
            it_behaves_like "hides the OFN navigation when needed only"

            it "hides the OFN navigation when visiting cart path" do
              visit main_app.cart_path
              expect(page).to have_no_selector ofn_navigation
            end

            it "hides the OFN navigation when visiting checkout path" do
              visit checkout_path
              expect(page).to have_content "Checkout now"
              expect(page).to have_content "Order ready for "
              expect(page).to have_no_selector ofn_navigation
            end
          end

          context "when the split checkout is disabled" do
            it_behaves_like "hides the OFN navigation when needed only for the checkout"
          end

          context "when the split checkout is enabled" do
            before do
              Flipper.enable(:split_checkout)
            end

            it_behaves_like "hides the OFN navigation when needed only for the checkout"
          end
        end

        context "when the user has a complete order" do
          let(:complete_order) {
            create(:order_with_credit_payment,
                   user: nil,
                   email: "guest@user.com",
                   distributor: distributor,
                   order_cycle: order_cycle)
          }
          before do
            set_order(complete_order)
          end

          shared_examples "hides the OFN navigation when needed only for the order confirmation" do
            it "hides" do
              visit order_path(complete_order, order_token: complete_order.token)
              expect(page).to have_no_selector ofn_navigation
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
    end
  end

  context "when the white label feature is deactivated" do
    before do
      Flipper.disable(:white_label)
    end

    it_behaves_like "does not hide the OFN navigation"
  end
end
