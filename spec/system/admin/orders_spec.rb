# frozen_string_literal: true

require "system_helper"

RSpec.describe '
    As an administrator
    I want to manage orders
' do
  include AuthenticationHelper
  include WebHelper

  let(:owner) { create(:user) }
  let(:owner2) { create(:user) }
  let(:customer) { create(:user) }
  let(:customer2) { create(:user) }
  let(:customer3) { create(:user) }
  let(:customer4) { create(:user) }
  let(:customer5) { create(:user) }
  let(:billing_address) { create(:address, :randomized) }
  let(:billing_address2) { create(:address, :randomized) }
  let(:billing_address3) { create(:address, :randomized) }
  let(:billing_address4) { create(:address, :randomized) }
  let(:billing_address5) { create(:address, :randomized) }
  let(:product) { create(:simple_product) }
  let(:distributor) {
    create(:distributor_enterprise, owner:, with_payment_and_shipping: true,
                                    charges_sales_tax: true)
  }
  let(:distributor2) { create(:distributor_enterprise_with_tax, owner:) }
  let(:distributor3) {
    create(:distributor_enterprise, owner:, with_payment_and_shipping: true,
                                    charges_sales_tax: true)
  }
  let(:distributor4) {
    create(:distributor_enterprise, owner:, with_payment_and_shipping: true,
                                    charges_sales_tax: true)
  }
  let(:distributor5) { create(:distributor_enterprise, owner: owner2, charges_sales_tax: true) }
  let!(:shipping_method) {
    create(:shipping_method_with, :pickup, name: "Pick up at the farm",
                                           distributors: [distributor, distributor2, distributor3])
  }
  let!(:shipping_method2) {
    create(:shipping_method_with, :delivery, name: "Home delivery to your convenience",
                                             distributors: [distributor4, distributor5])
  }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor, distributor2,
                                                            distributor3, distributor4],
                                variants: [product.variants.first])
  end

  context "with a complete order" do
    let(:order) do
      create(:order_with_totals_and_distribution, user: customer, distributor:,
                                                  order_cycle:,
                                                  state: 'complete', payment_state: 'balance_due',
                                                  bill_address_id: billing_address.id)
    end

    let!(:order_cycle2) {
      create(:simple_order_cycle, name: 'Two', orders_close_at: 2.weeks.from_now)
    }
    let!(:order_cycle3) {
      create(:simple_order_cycle, name: 'Three', orders_close_at: 3.weeks.from_now)
    }
    let!(:order_cycle4) {
      create(:simple_order_cycle, name: 'Four', orders_close_at: 4.weeks.from_now)
    }
    let!(:order_cycle5) do
      create(:simple_order_cycle, name: 'Five', coordinator: distributor5,
                                  distributors: [distributor5], variants: [product.variants.first])
    end

    let!(:order2) {
      create(:order_ready_to_ship, user: customer2, distributor: distributor2,
                                   order_cycle: order_cycle2, completed_at: 2.days.ago,
                                   bill_address_id: billing_address2.id)
    }
    let!(:order3) {
      create(:order_with_credit_payment, user: customer3, distributor: distributor3,
                                         order_cycle: order_cycle3,
                                         bill_address_id: billing_address3.id)
    }
    let!(:order4) {
      create(:order_with_credit_payment, user: customer4, distributor: distributor4,
                                         order_cycle: order_cycle4,
                                         bill_address_id: billing_address4.id)
    }
    let!(:order5) {
      create(:order_ready_to_ship, user: customer5, distributor: distributor5,
                                   order_cycle: order_cycle5,
                                   bill_address_id: billing_address5.id)
    }

    describe "filters" do
      before do
        login_as_admin
        visit spree.admin_orders_path
      end

      it "order cycles appear in descending order by close date on orders page" do
        tomselect_open('q_order_cycle_id_in').click

        expect(find('#q_order_cycle_id_in',
                    visible: :all)[:innerHTML]).to have_content(/.*Four.*Three.*Two.*Five/m)
      end

      it "filter by multiple order cycles" do
        tomselect_multiselect 'Two', from: 'q[order_cycle_id_in][]'
        tomselect_multiselect 'Three', from: 'q[order_cycle_id_in][]'

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 and 3 should show, but not 4
        expect(page).to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by distributors" do
        tomselect_multiselect distributor2.name.to_s, from: 'q[distributor_id_in][]'
        tomselect_multiselect distributor4.name.to_s, from: 'q[distributor_id_in][]'

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 and 4 should show, but not 3
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).to have_content order4.number
      end

      it "filter by complete date" do
        find("input.datepicker").click
        select_dates_from_daterangepicker(order3.completed_at.yesterday,
                                          order4.completed_at.tomorrow)

        page.find('.filter-actions .button[type=submit]').click

        # Order 3 and 4 should show, but not 2
        expect(page).not_to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).to have_content order4.number
      end

      it "filter by email" do
        fill_in "Email", with: customer3.email

        page.find('.filter-actions .button[type=submit]').click

        # Order 3 should show, but not 2 and 4
        expect(page).not_to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by customer first and last names" do
        # NOTE: this field refers to the name given in billing addresses and not to customer name
        # filtering by first name
        fill_in "First name begins with", with: billing_address2.firstname
        page.find('.filter-actions .button[type=submit]').click
        # Order 2 should show, but not 3 and 4
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number

        find("#clear_filters_button").click
        # filtering by last name

        fill_in "Last name begins with", with: billing_address4.lastname
        page.find('.filter-actions .button[type=submit]').click
        # Order 4 should show, but not 2 and 3
        expect(page).not_to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).to have_content order4.number

        find("#clear_filters_button").click
        # filtering by first and last name together

        fill_in "First name begins with", with: billing_address3.firstname
        fill_in "Last name begins with", with: billing_address3.lastname
        page.find('.filter-actions .button[type=submit]').click
        # Order 3 should show, but not 2 and 4
        expect(page).not_to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by shipping methods" do
        order2.select_shipping_method(shipping_method.id)
        order4.select_shipping_method(shipping_method2.id)

        tomselect_search_and_select "Pick up at the farm", from: 'shipping_method_id'
        page.find('.filter-actions .button[type=submit]').click
        # Order 2 should show, but not 3 and 5
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number

        find("#clear_filters_button").click

        tomselect_search_and_select "Home delivery to your convenience", from: 'shipping_method_id'
        page.find('.filter-actions .button[type=submit]').click
        # Order 4 should show, but not 2 and 3
        expect(page).not_to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).to have_content order4.number
      end

      it "filter by invoice number" do
        fill_in "Order number:", with: order2.number

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 should show, but not 3 and 4
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by order state" do
        order.update(state: "payment")

        uncheck 'Only show complete orders'
        page.find('.filter-actions .button[type=submit]').click

        expect(page).to have_content order.number
        expect(page).to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).to have_content order4.number
        expect(page).to have_content order5.number

        tomselect_search_and_select "payment", from: 'q[state_eq]'

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 should show, but not 3 and 4
        expect(page).to have_content order.number
        expect(page).not_to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number
        expect(page).not_to have_content order5.number
      end
    end

    context "cart orders" do
      let!(:order_empty) {
        create(:order_with_line_items, user: customer2, distributor: distributor2,
                                       line_items_count: 0)
      }

      let!(:order_not_empty) {
        create(:order_with_line_items, user: customer2, distributor: distributor2,
                                       line_items_count: 1)
      }

      let!(:order_not_empty_no_address) {
        create(:order_with_line_items, line_items_count: 1, user: customer2,
                                       distributor: distributor2, bill_address_id: nil,
                                       ship_address_id: nil)
      }

      before do
        login_as_admin
        visit spree.admin_orders_path
        uncheck 'Only show complete orders'
        tomselect_search_and_select "cart", from: 'q[state_eq]'
        page.find('.filter-actions .button[type=submit]').click
      end

      it "displays non-empty cart orders" do
        # empty cart order does not appear in the results
        expect(page).not_to have_content order_empty.number

        # non-empty cart order, with bill- and ship-address appear in the results
        expect(page).to have_content order_not_empty.number

        # non-empty cart order, with no with bill- and ship-address appear in the results
        expect(page).to have_content order_not_empty_no_address.number

        # And the same orders are displayed when sorting by name:
        find("th a", text: "Name").click

        expect(page).not_to have_content order_empty.number
        expect(page).to have_content order_not_empty.number
        expect(page).to have_content order_not_empty_no_address.number
      end
    end

    describe "ordering" do
      context "orders with different completion dates" do
        before do
          order2.update!(completed_at: 2.weeks.ago)
          order3.update!(completed_at: 3.weeks.ago)
          order4.update!(completed_at: 4.weeks.ago)
          order5.update!(completed_at: 5.weeks.ago)
          login_as_admin
          visit spree.admin_orders_path
        end
        it "orders by completion date" do
          find("a", text: 'Completed At').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'Completed At').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different order numbers" do
        before do
          order2.update!(number: "R555555555")
          order3.update!(number: "R444444444")
          order4.update!(number: "R333333333")
          order5.update!(number: "R222222222")
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by order number" do
          find("a", text: 'Number').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'Number').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different states" do
        before do
          order2.update!(state: "payment")
          order3.update!(state: "complete")
          order4.update!(state: "cart")
          order5.cancel
          login_as_admin
          visit spree.admin_orders_path
          uncheck 'Only show complete orders'
          page.find('.filter-actions .button[type=submit]').click
        end

        it "orders by order state" do
          find("a", text: 'State').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'State').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different payment states" do
        before do
          Spree::Payment.where(order_id: order2.id).first.update!(amount: 50.0)
          Spree::Payment.where(order_id: order3.id).first.update!(amount: 100.0)
          Spree::Payment.where(order_id: order4.id).first.update!(amount: 10.0)
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by payment state" do
          find("a", text: 'Payment State').click # sets ascending ordering
          expect(page).to have_content(/#{order4.number}.*#{order3.number}.*#{order2.number}/m)
          find("a", text: 'Payment State').click # sets descending ordering
          expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}/m)
        end
      end

      context "orders with different shipment states" do
        before do
          Spree::Payment.where(order_id: order2.id).first.update!(amount: 50.0)
          Spree::Payment.where(order_id: order3.id).first.update!(amount: 100.0)
          Spree::Payment.where(order_id: order4.id).first.update!(amount: 10.0)
          order2.ship
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by shipment state" do
          find("a", text: 'Shipment State').click # sets ascending ordering
          expect(page).to have_content(/#{order4.number}.*#{order3.number}.*#{order2.number}/m)
          find("a", text: 'Shipment State').click # sets descending ordering
          expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}/m)
        end
      end

      context "orders from different customers" do
        before do
          order2.update!(email: "jkl@jkl.com")
          order3.update!(email: "ghi@ghi.com")
          order4.update!(email: "def@def.com")
          order5.update!(email: "abc@abc.com")
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by customer email" do
          find("a", text: 'Email').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'Email').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different billing addresses" do
        before do
          billing_address2.update!(firstname: "Mad", lastname: "Hatter")
          billing_address3.update!(firstname: "Alice", lastname: "Smith")
          billing_address4.update!(firstname: "Cheshire", lastname: "Cat")
          billing_address5.update!(firstname: "Bob", lastname: "Smith")
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by last name then first name" do
          find("a", text: 'Name').click # sets ascending ordering
          expect(page).to have_content(
            /#{order4.number}.*#{order2.number}.*#{order3.number}.*#{order5.number}/m
          )
          find("a", text: 'Name').click # sets descending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order3.number}.*#{order2.number}.*#{order4.number}/m
          )
        end
      end

      context "displaying order special instructions" do
        before do
          order3.update(special_instructions: "Leave it next to the porch. Thanks!")
          login_as_admin
          visit spree.admin_orders_path
        end

        it "displays a note with order instructions" do
          within "tr#order_#{order3.id}" do
            expect(page).to have_content "Note"
            find(".icon-warning-sign").hover
            expect(page).to have_content(/#{order3.special_instructions}/i)
          end
        end
      end

      context "orders with different order totals" do
        before do
          order2.contents.update_item(Spree::LineItem.find_by(order_id: order2.id), { quantity: 5 })
          order3.contents.update_item(Spree::LineItem.find_by(order_id: order3.id), { quantity: 4 })
          order4.contents.update_item(Spree::LineItem.find_by(order_id: order4.id), { quantity: 3 })
          order5.contents.update_item(Spree::LineItem.find_by(order_id: order5.id), { quantity: 2 })

          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by order total" do
          find("a", text: 'Total').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'Total').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end
    end

    context "select/unselect all orders" do
      before do
        login_as_admin
        visit spree.admin_orders_path
      end

      it "by clicking on the checkbox in the table header" do
        # select all orders
        page.find("#listing_orders thead th:first-child input[type=checkbox]").click
        expect(page.find(
                 "#listing_orders tbody tr td:first-child input[type=checkbox]"
               )).to be_checked
        # enables print invoices button
        page.find("span.icon-reorder", text: "Actions").click
        expect(page).to have_content "Print Invoices"
        # unselect all orders
        page.find("#listing_orders thead th:first-child input[type=checkbox]").trigger("click")
        expect(page.find(
                 "#listing_orders tbody tr td:first-child input[type=checkbox]"
               )).not_to be_checked
        # disables print invoices button not clickable
        expect { find("span.icon-reorder", text: "Actions").click }
          .to raise_error(Capybara::Cuprite::MouseEventFailed)
        expect(page).not_to have_content "Print Invoices"
      end
    end

    context "pagination" do
      before do
        # creates 15 orders additional to the 4 orders
        15.times { create(:order_ready_to_ship) }
        login_as_admin
        visit spree.admin_orders_path
      end

      it "displays pagination options" do
        # displaying 15 orders (one order per table row)
        within('tbody') do
          expect(page).to have_css('tr', count: 15)
        end
        # pagination options refers 19 orders
        expect(page).to have_content "19 Results found. Viewing 1 to 15."
        page.find(".per-page-dropdown .ts-control .item").click # toggling the pagination dropdown
        expect(page).to have_content "15 per page"
        expect(page).to have_content "50 per page"
        expect(page).to have_content "100 per page"
      end

      it "changes pagination and displays entries" do
        within ".pagination" do
          expect(page).not_to have_css('button.page.prev')
          expect(page).to have_css('button.page.next')
          click_on "2"
        end
        # table displays 4 entries
        within('tbody') do
          expect(page).to have_css('tr', count: 4)
        end
        expect(page).to have_content "19 Results found. Viewing 16 to 19."
        within ".pagination" do
          expect(page).to have_css('button.page.prev')
          expect(page).not_to have_css('button.page.next')
        end
      end
    end

    context "with a capturable order" do
      before do
        order.finalize! # ensure order has a payment to capture
        order.payments << create(:check_payment, order:, amount: order.total)
      end

      it "capture payment" do
        login_as_admin
        visit spree.admin_orders_path
        expect(page).to have_current_path spree.admin_orders_path

        # click the 'capture' link for the order
        page.find("button.icon-capture").click

        expect(page).to have_css "i.success"
        expect(page).to have_css "button.icon-road"

        # check the order was captured
        expect(order.reload.payment_state).to eq "paid"

        # we should still be on the same page
        expect(page).to have_current_path spree.admin_orders_path
      end

      it "ship order from the orders index page and send email" do
        order.payments.first.capture!
        login_as_admin
        visit spree.admin_orders_path

        page.find("button.icon-road").click

        within ".reveal-modal" do
          expect {
            find_button("Confirm").click
          }.to enqueue_job(ActionMailer::MailDeliveryJob).exactly(:once)
        end
        expect(page).to have_css "i.success"
        expect(order.reload.shipments.any?(&:shipped?)).to be true
        expect(order.shipment_state).to eq("shipped")
      end

      it "ship order from the orders index page and do not send email" do
        order.payments.first.capture!
        login_as_admin
        visit spree.admin_orders_path

        page.find("button.icon-road").click

        within ".reveal-modal" do
          uncheck 'Send a shipment/pick up notification email to the customer.'
          expect {
            find_button("Confirm").click
          }.not_to enqueue_job(ActionMailer::MailDeliveryJob)
        end
        expect(page).to have_css "i.success"
        expect(order.reload.shipments.any?(&:shipped?)).to be true
        expect(order.shipment_state).to eq("shipped")
      end

      context "mouse-hovering" do
        before do
          login_as_admin
          visit spree.admin_orders_path
        end

        it "displays Ship and Capture tooltips" do
          within "tr#order_#{order2.id}" do
            # checks shipment state
            expect(page).to have_content "READY"

            # mouse-hovers and finds tooltip
            find(".icon-road").hover
            expect(page).to have_content "Ship"
          end

          within "tr#order_#{order.id}" do
            # checks shipment state
            expect(page).to have_content "PENDING"

            # mouse-hovers and finds tooltip
            find(".icon-capture").hover
            expect(page).to have_content "Capture"
          end
        end

        it "displays Ship and Edit tooltips, after capturing a payment" do
          within "tr#order_#{order.id}" do
            # checks the order has an uncaptured payment
            find(".icon-capture").hover
            expect(page).to have_content "Capture"

            # captures the payment
            find(".icon-capture").click
            expect(page).not_to have_content "Capture"

            # checks shipment state
            expect(page).to have_content "READY"

            # move away from the Ship button so we can trigger the mouseenter event by moving back.
            # We are already on the "Ship" button when it gets rendered because of
            # the previous click
            find(".icon-edit").hover
            # mouse-hovers and finds Ship tooltip
            find(".icon-road").hover
            expect(page).to have_content "Ship"

            # mouse-hovers and finds Edit tooltip
            find(".icon-edit").hover
            expect(page).to have_content "Edit"
          end
        end

        it "displays Edit tooltip" do
          within "tr#order_#{order.id}" do
            # checks shipment state
            expect(page).to have_content "PENDING"

            # mouse-hovers and finds tooltip
            find(".icon-edit").hover
            expect(page).to have_content "Edit"
          end
        end
      end
    end
  end

  context "with incomplete order" do
    it "can edit order" do
      incomplete_order = create(:order_with_line_items, distributor:,
                                                        order_cycle:,
                                                        line_items_count: 1)

      login_as_admin
      visit spree.admin_orders_path
      uncheck 'Only show complete orders'
      page.find('button[type=submit]').click

      find(".icon-edit").click

      expect(page).to have_current_path spree.edit_admin_order_path(incomplete_order)
    end
  end

  context "test the 'Only show the complete orders' checkbox" do
    it "display or not incomplete order" do
      incomplete_order = create(:order_with_line_items, distributor:,
                                                        order_cycle:,
                                                        line_items_count: 1)
      complete_order = create(
        :order_with_line_items,
        distributor:,
        order_cycle:,
        user: customer,
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago,
        line_items_count: 1
      )

      empty_complete_order = create(
        :order_with_line_items,
        distributor:,
        order_cycle:,
        user: customer,
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago,
        line_items_count: 0
      )

      empty_order = create(:order, distributor:, order_cycle:)

      login_as_admin
      visit spree.admin_orders_path
      expect(page).to have_content complete_order.number
      expect(page).to have_content empty_complete_order.number
      expect(page).not_to have_content incomplete_order.number
      expect(page).not_to have_content empty_order.number

      uncheck 'Only show complete orders'
      page.find('button[type=submit]').click

      expect(page).to have_content complete_order.number
      expect(page).to have_content incomplete_order.number
      expect(page).not_to have_content empty_order.number
    end
  end

  context "save the filter params" do
    let!(:shipping_method) { create(:shipping_method, name: "UPS Ground") }
    let!(:user) { create(:user, email: 'an@email.com') }
    let!(:order) do
      create(
        :order,
        distributor:,
        order_cycle:,
        user:,
        number: "R123456",
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago
      )
    end
    before :each do
      login_as_admin
      visit spree.admin_orders_path

      # Specify each filters
      uncheck 'Only show complete orders'
      fill_in "Order number", with: "R123456"
      tomselect_multiselect order_cycle.name, from: 'q[order_cycle_id_in][]'
      tomselect_multiselect distributor.name, from: 'q[distributor_id_in][]'
      tomselect_select shipping_method.name, from: 'shipping_method_id'
      tomselect_select "complete", from: 'q[state_eq]'
      fill_in "Email", with: user.email
      fill_in "First name begins with", with: "J"
      fill_in "Last name begins with", with: "D"
      find("input.datepicker").click
      select_dates_from_daterangepicker(Time.zone.at(1.week.ago), Time.zone.now.tomorrow)

      page.find('.button[type=submit]').click
    end

    it "when reloading the page" do
      page.driver.refresh

      # Check every filters to be equal
      expect(find_field("Only show complete orders")).not_to be_checked
      expect(find_field("Order number").value).to eq "R123456"
      expect(find("#shipping_method_id-ts-control .item").text).to eq shipping_method.name
      expect(find("#q_state_eq-ts-control .item").text).to eq "complete"
      expect(find("#q_distributor_id_in").value).to eq [distributor.id.to_s]
      expect(find("#q_order_cycle_id_in").value).to eq [order_cycle.id.to_s]
      expect(find_field("Email").value).to eq user.email
      expect(find_field("First name begins with").value).to eq "J"
      expect(find_field("Last name begins with").value).to eq "D"
      expect(find("input.datepicker").value).to eq(
        "#{1.week.ago.strftime('%Y-%m-%d')} to #{Time.zone.now.tomorrow.strftime('%Y-%m-%d')}"
      )
    end

    it "and clear filters" do
      find("#clear_filters_button").click
      expect(find_field("Only show complete orders")).to be_checked
      expect(find_field("Order number").value).to eq ""
      expect(find("#shipping_method_id").value).to be_empty
      expect(find("#q_state_eq").value).to be_empty
      expect(find("#q_distributor_id_in").value).to be_empty
      expect(find("#q_order_cycle_id_in").value).to be_empty
      expect(find_field("Email").value).to be_empty
      expect(find_field("First name begins with").value).to be_empty
      expect(find_field("Last name begins with").value).to be_empty
      expect(find("input.datepicker").value).to be_empty
    end
  end
end
