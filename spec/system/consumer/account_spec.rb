# frozen_string_literal: true

require 'spec_helper'

feature '
    As a consumer
    I want to view my order history with each hub
    and view any outstanding balance.
', js: true do
  include UIComponentHelper
  include AuthenticationHelper

  let(:user) { create(:user) }
  let!(:distributor1) { create(:distributor_enterprise) }
  let!(:distributor2) { create(:distributor_enterprise) }
  let!(:distributor_credit) { create(:distributor_enterprise) }
  let!(:distributor_without_orders) { create(:distributor_enterprise) }

  context "as a logged in user" do
    before do
      login_as user
    end

    context "with completed orders" do
      let(:order_cycle) { create(:simple_order_cycle) }
      let!(:d1o1) {
        create(:completed_order_with_totals, distributor: distributor1, user: user, total: 10_000,
                                             order_cycle: order_cycle)
      }
      let!(:d1o2) {
        create(:order_without_full_payment, distributor: distributor1, user: user, total: 5000,
                                            order_cycle: order_cycle)
      }
      let!(:d2o1) { create(:completed_order_with_totals, distributor: distributor2, user: user) }
      let!(:credit_order) {
        create(:order_with_credit_payment, distributor: distributor_credit, user: user)
      }

      before do
        credit_order.update_order!
      end

      it "shows all hubs that have been ordered from with balance or credit" do
        # Single test to avoid re-rendering page
        visit "/account"

        # No distributors allow changes to orders
        expect(page).to have_no_content I18n.t('spree.users.orders.open_orders')

        expect(page).to have_content I18n.t('spree.users.orders.past_orders')

        # Lists all other orders
        expect(page).to have_content d1o1.number.to_s
        expect(page).to have_content d1o2.number.to_s
        expect(page).to have_link(distributor1.name,
                                  href: "#{distributor1.permalink}/shop", count: 2)
        expect(page).to have_content d2o1.number.to_s
        expect(page).to have_link(distributor2.name,
                                  href: "#{distributor2.permalink}/shop", count: 1)
        expect(page).to have_content credit_order.number.to_s
        expect(page).to have_link(distributor_credit.name,
                                  href: "#{distributor_credit.permalink}/shop", count: 1)

        # Viewing transaction history
        find("a", text: /#{I18n.t('spree.users.show.tabs.transactions')}/i).click

        # It shows all hubs that have been ordered from with balance or credit
        expect(page).to have_content distributor1.name
        expect(page).to have_link(distributor1.name,
                                  href: "#{distributor1.permalink}/shop", count: 1)
        expect(page).to have_content distributor2.name
        expect(page).to have_link(distributor2.name,
                                  href: "#{distributor2.permalink}/shop", count: 1)
        expect(page).not_to have_content distributor_without_orders.name

        expect(page).to have_content distributor1.name + "\n" + "Balance due"
        expect(page).to have_content distributor_credit.name + "\nCredit"

        # It reveals table of orders for distributors when clicked
        expand_active_table_node distributor1.name
        expect(page).to have_link "Order " + d1o1.number, href: "/orders/#{d1o1.number}"

        expand_active_table_node distributor2.name
        expect(page).not_to have_content "Order " + d1o1.number.to_s
      end

      context "when there is at least one changeable order" do
        before do
          distributor1.update(allow_order_changes: true)
        end

        it "shows such orders in a section labelled 'Open Orders'" do
          visit '/account'
          expect(page).to have_content I18n.t('spree.users.orders.open_orders')

          expect(page).to have_link d1o1.number, href: order_path(d1o1)
          expect(page).to have_link d1o2.number, href: order_path(d1o2)
          expect(page).to have_link(distributor1.name,
                                    href: "#{distributor1.permalink}/shop", count: 2)
          expect(page).to have_link I18n.t('spree.users.open_orders.cancel'),
                                    href: cancel_order_path(d1o1)
          expect(page).to have_link I18n.t('spree.users.open_orders.cancel'),
                                    href: cancel_order_path(d1o2)
        end
      end
    end

    context "without any completed orders" do
      it "displays an appropriate message" do
        visit "/account"
        expect(page).to have_content I18n.t(:you_have_no_orders_yet)
      end
    end
  end
end
