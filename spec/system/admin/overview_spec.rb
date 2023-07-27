# frozen_string_literal: true

require 'system_helper'

describe '
  As a backend user
  I want to be given information about the state of my enterprises, products and order cycles
' do
  include WebHelper
  include AuthenticationHelper

  context "as an enterprise user" do
    before do
      @enterprise_user = create(:user)
      allow_any_instance_of(Spree::Admin::OverviewController).to receive(:spree_current_user)
        .and_return @enterprise_user
      login_as @enterprise_user
    end

    context "with an enterprise" do
      let(:d1) { create(:distributor_enterprise) }

      before :each do
        @enterprise_user.enterprise_roles.build(enterprise: d1).save
      end

      it "displays a link to the map page" do
        visit '/admin'
        expect(page).to have_selector ".dashboard_item h3", text: "Your profile live"
        expect(page).to have_selector ".dashboard_item .button.bottom",
                                      text: "SEE #{d1.name.upcase} LIVE"
      end

      context "when visibilty is set to false" do
        before do
          d1.visible = "only_through_links"
          d1.save!
        end

        it "displays a message telling how to set visibility" do
          visit '/admin'
          expect(page).to have_selector ".alert-box",
                                        text: "To allow people to find you, turn on your " \
                                              "visibility under Manage #{d1.name}."
        end
      end

      context "when user is a profile only" do
        before do
          d1.sells = "none"
          d1.save!
        end

        it "does not show a products item" do
          visit '/admin'
          expect(page).to have_no_selector "#products"
        end
      end
    end

    context "with multiple enterprises" do
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      let(:non_distributor_enterprise) { create(:enterprise, sells: 'none') }

      before do
        @enterprise_user.enterprise_roles.build(enterprise: d1).save
        @enterprise_user.enterprise_roles.build(enterprise: d2).save
        @enterprise_user
          .enterprise_roles.build(enterprise: non_distributor_enterprise).save
      end

      it "displays information about the enterprise" do
        visit '/admin'

        expect(page).to have_selector ".dashboard_item#enterprises h3", text: "My Enterprises"
        expect(page).to have_selector ".dashboard_item#products"
        expect(page).to have_selector ".dashboard_item#order_cycles"
        expect(page).to have_selector ".dashboard_item#enterprises .list-item", text: d1.name
        expect(page).to have_selector ".dashboard_item#enterprises .list-item",
                                      text: non_distributor_enterprise.name
        expect(page).to have_selector ".dashboard_item#enterprises .button.bottom",
                                      text: "MANAGE MY ENTERPRISES"
      end

      context "but no products or order cycles" do
        it "prompts the user to create a new product and to manage order cycles" do
          visit '/admin'
          expect(page).to have_selector ".dashboard_item#products h3", text: "Products"
          expect(page).to have_selector ".dashboard_item#products .list-item",
                                        text: "You don't have any active products."
          expect(page).to have_selector ".dashboard_item#products .button.bottom",
                                        text: "CREATE A NEW PRODUCT"
          expect(page).to have_selector ".dashboard_item#order_cycles h3", text: "Order Cycles"
          expect(page).to have_selector ".dashboard_item#order_cycles .list-item",
                                        text: "You don't have any active order cycles."
          expect(page).to have_selector ".dashboard_item#order_cycles .button.bottom",
                                        text: "MANAGE ORDER CYCLES"
        end
      end

      context "and at least one product and active order cycle" do
        let(:oc1) { create(:simple_order_cycle, distributors: [d1]) }
        let(:p1) { create(:product, distributor: d1) }

        it "displays information about products and order cycles" do
          visit '/admin'
          expect(page).to have_selector ".dashboard_item#products h3", text: "Products"
          expect(page).to have_selector ".dashboard_item#products .list-item",
                                        text: "You don't have any active products."
          expect(page).to have_selector ".dashboard_item#products .button.bottom",
                                        text: "CREATE A NEW PRODUCT"
          expect(page).to have_selector ".dashboard_item#order_cycles h3", text: "Order Cycles"
          expect(page).to have_selector ".dashboard_item#order_cycles .list-item",
                                        text: "You don't have any active order cycles."
          expect(page).to have_selector ".dashboard_item#order_cycles .button.bottom",
                                        text: "MANAGE ORDER CYCLES"
        end
      end
    end
  end
end
